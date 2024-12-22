function removal(seg, segnum, between, label, near, centroids, url, grad, texthist)
    disp 'Removal'
    im = imread(url);
    epsilon = 0.01;
    l_label = label;
    
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
    
    % HSV renk uzayına dönüşüm ve histogram hesaplama
    c_im = double(rgb2hsv(im));
    c1_im = c_im(:,:,1);
    c2_im = c_im(:,:,2);
    c3_im = c_im(:,:,3);
    lab = calHsvHist(c_im, seg, segnum);
    
    % En yakın komşuları bulma
    for i = 1:size(label,2)
        if label(i) == 0
            j = near(i);
            num = 0;
            while label(j) ~= 255
                [value, j] = min(between(i,:));
                between(i,j) = 100;
                num = num + 1;
            end
            near(i) = j;
            if num ~= 21
                plot([centroids(i,1) centroids(j,1)], [centroids(i,2) centroids(j,2)], 'r');
            end
        end
    end
    
    % Histogram eşleştirme ile gölge kaldırma
    for i = 1:size(label, 2)
        if label(i) == 0 && label(near(i)) == 255
            j = near(i);
            temp3 = reshape(lab(j,101:150),[50,1]);
            c3_im(seg==i) = hist_match(c3_im(seg==i),temp3);
            temp2 = reshape(lab(j,51:100),[50,1]);
            c2_im(seg==i) = hist_match(c2_im(seg==i),temp2);
            temp1 = reshape(lab(j,1:50),[50,1]);
            c1_im(seg==i) = hist_match(c1_im(seg==i),temp1);
        end
    end
    
    c_im(:,:,1) = c1_im;
    c_im(:,:,2) = c2_im;
    c_im(:,:,3) = c3_im;
    
    % Kenar yumuşatma işlemleri
    test_im = hsv2rgb(c_im);
    circle = zeros(size(c_im, 1), size(c_im, 2));
    
    % Kenar piksellerini tespit et
    for i = 8:size(c_im, 1)-8
        for j = 8:size(c_im, 2)-8
            if label(seg(i,j)) ~= label(seg(i-1,j)) || label(seg(i,j)) ~= label(seg(i+1,j)) || ...
               label(seg(i,j)) ~= label(seg(i,j-1)) || label(seg(i,j)) ~= label(seg(i,j+1))
                circle(i-1:i+1,j-1:j+1) = 1;
            end
        end
    end
    
    % Gaussian bulanıklaştırma
    h = fspecial('gaussian', 15, 15);
    pattern = imfilter(test_im, h);
    label = l_label;
    
    % Kenar yumuşatma uygula
    for i = 1:segnum
        if label(i) == 0
            for ch = 1:3
                fig = test_im(:,:,ch);
                for x = 20:size(fig, 1) - 20
                    for y = 20:size(fig,2) - 20
                        if seg(x,y) == i && seg(x-4, y) ~= i && circle(x,y) == 1
                            fig(x,y) = pattern(x,y,ch);
                            fig(x-4,y) = pattern(x,y,ch);
                        elseif seg(x,y) == i && seg(x+4, y) ~= i && circle(x,y) == 1
                            fig(x,y) = pattern(x,y,ch);
                            fig(x+4,y) = pattern(x,y,ch);
                        elseif seg(x,y) == i && seg(x, y+4) ~= i && circle(x,y) == 1
                            fig(x,y) = pattern(x,y,ch);
                            fig(x,y+4) = pattern(x,y,ch);
                        elseif seg(x,y) == i && seg(x, y-4) ~= i && circle(x,y) == 1
                            fig(x,y) = pattern(x,y,ch);
                            fig(x,y-4) = pattern(x,y,ch);
                        end
                    end
                end
                test_im(:,:,ch) = fig;
            end
        end
    end
    
    imshow(test_im);
end
