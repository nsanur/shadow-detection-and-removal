function [seg, segnum, between, near, centroids, label, grad, texthist]=detect(url)
    % Görüntüyü oku
    im = imread(url);
    
    % Edison wrapper ile görüntü segmentasyonu
    disp 'Segmenting'
    [dummy seg] = edison_wrapper(im, @RGB2Luv, ...
        'SpatialBandWidth', 9, 'RangeBandWidth', 15, ...
        'MinimumRegionArea', 200);
    seg = seg + 1;
    segnum = max(max(seg));

    % Renk uzayı hesaplamaları
    disp 'Detect'
    hsi = calHsi(im, seg, segnum);
    hsv = calHsv(im, seg, segnum);
    ycbcr = calYcbcr(im, seg, segnum);
    texthist = calcTextonHist(im, seg, segnum);
    grad = calGradient(im, seg, segnum);
    
    % Şekil özelliklerini hesapla
    shapemean = calcShapeMean(seg, segnum);
    area = shapemean.area;
    centroids = shapemean.center;
    
    % Renk normalizasyonu
    ycbcr(:,1) = ycbcr(:,1) / max(ycbcr(:,1));
    hsv(:,1) = hsv(:,1) / max(hsv(:,1));
    
    % Bölgeler arası mesafe hesaplama
    between = zeros([segnum, segnum]);
    for i = 1:size(between, 1)
        for j = 1:size(between, 2)
            distance = [centroids(i,1), centroids(i,2); centroids(j,1), centroids(j,2)];
            distance = sqrt((distance(1,1)-distance(2,1))^2 + (distance(1,2)-distance(2,2))^2) / max(size(im, 1), size(im, 2));
            between(i, j) = sum(abs(grad(i,:) - grad(j,:))) + sum(abs(texthist(i,:) - texthist(j,:))) + distance;
            if i == j
                between(i,j) = 100;
            end
        end
    end
    
    % Kenar tespiti
    nim = im;
    [gx gy] = gradient(double(seg));
    eim = (gx.^2+gy.^2)>1e-10;
    t = nim(:,:,1); t(eim)=0; nim(:,:,1)=t;
    t = nim(:,:,2); t(eim)=0; nim(:,:,2)=t;
    t = nim(:,:,3); t(eim)=0; nim(:,:,3)=t;
    
    % En yakın komşuları bul
    near = zeros([1, segnum]);
    for i = 1:segnum
        [value, near(1, i)] = min(between(i,:));
        j = near(1, i);
        plot([centroids(i,1) centroids(j,1)], [centroids(i,2) centroids(j,2)], 'b');
    end
    
    % Renk özelliklerini hesapla
    hh = zeros([3, length(near)]);
    for i = 1:length(near)
        j = near(i);
        max_hsv = max(hsv(i,3), hsv(j,3));
        min_hsv = min(hsv(i,3), hsv(j,3));
        max_ycbcr = max(ycbcr(i,1), ycbcr(j,1));
        min_ycbcr = min(ycbcr(i,1), ycbcr(j,1));
        max_hsi = max((hsi(i,1)+1/255)/(hsi(i,3)+1/255), (hsi(j,1)+1/255)/(hsi(j,3)+1/255));
        min_hsi = min((hsi(i,1)+1/255)/(hsi(i,3)+1/255), (hsi(j,1)+1/255)/(hsi(j,3)+1/255));
        hh(2, i) = min_ycbcr/max_ycbcr;
        hh(1, i) = min_hsi / max_hsi;
    end
    
    % K-means kümeleme
    x = reshape(hsi(:,1)./hsi(:,3), [size(hsi,1),1]);
    [idx,center] = kmeans(x,2);
    c_std = zeros([2,1]);
    temp = idx == 1;
    c_std(1,1) = std(x(temp));
    temp = idx == 2;
    c_std(2,1) = std(x(temp));
    
    if center(1,1) > center(2,1)
        center = sort(center);
        temp = c_std(1,1);
        c_std(1,1) = c_std(2,1);
        c_std(2,1) = temp;
    end
    
    % Gölge tespiti
    label = zeros([1, segnum]) + 255;
    ycbcr_copy = ycbcr;
    n_nonshadow = segnum;
    avg_y = mean(ycbcr(:,1));
    flag = 0;
    t_hsi = hsi(:,1) ./ hsi(:,3);
    level = graythresh(t_hsi);
    
    % İlk gölge tespiti
    for i = 1:segnum
        if ycbcr(i,1) < avg_y * 0.6
            label(i) = 0;
            ycbcr_copy(i,:) = 0;
            n_nonshadow = n_nonshadow - 1;
            flag = flag + 1;
        end
    end
    
    % Gölge bölgelerini iyileştirme
    refuse = zeros([1, segnum]);
    while 1
        update = 0;
        new = 0;
        max_v = 0;
        for i = 1:segnum
            val = hsi(i,1) / hsi(i, 3);
            temp1 = normcdf((val-center(2,1))/c_std(2,1));
            temp2 = normcdf(-(val-center(1,1))/c_std(1,1));
            if temp2 < temp1 && refuse(i) == 0 && label(i) == 255
                if temp1 > max_v
                    new = i;
                    max_v = temp1;
                    update = 1;
                end
            end
        end
        
        if update == 0 || max_v < 0.0028
            break;
        end
        
        label(new) = 0;
        j = near(new);
        vali = hsi(i,1) / hsi(i, 3);
        valj = hsi(j,1) / hsi(j, 3);
        if ((vali-center(2,1))/c_std(2,1)) - ((valj-center(2,1))/c_std(2,1)) > 3
            refuse(j) = 1;
            label(j) = 255;
        end
        ycbcr_copy(i,:) = 0;
        n_nonshadow = n_nonshadow - 1;
        flag = flag + 1;
    end
    
    % Son iyileştirmeler
    for i = 1:segnum
        if label(i) ~= 255
            continue
        end
        j = near(i);
        max_hsv = max(hsv(i,3), hsv(j,3));
        min_hsv = min(hsv(i,3), hsv(j,3));
        max_ycbcr = max(ycbcr(i,1), ycbcr(j,1));
        min_ycbcr = min(ycbcr(i,1), ycbcr(j,1));
        same = min_hsv / max_hsv + min_ycbcr / max_ycbcr + hh(1,i);
        if same > 2.5 && label(j) == 0
            label(i) = 0;
        end
    end
    imshow(label(seg))
end
