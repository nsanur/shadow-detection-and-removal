% % Gerekli kütüphaneleri ekle
% addpath('meanshift');
% addpath('libsvm/')
% addpath('./libsvm/matlab/');
% addpath('./etract_feature/');
% addpath('./utils/');
% 
% % Görüntü dosyasını tanımla ve oku
% url = "./images/3.jpg";
% figure;
% im = imread(url);
% imshow(im);
% title('Orijinal Görüntü');
% 
% % Dosya kontrolü
% if exist(url, 'file') == 2
%     disp(['Dosya mevcut: ', url]);
% else
%     error(['Dosya bulunamadı: ', url]);
% end
% 
% % Gölge tespiti ve kaldırma işlemleri
% [seg, segnum, between, near, centroids, label, grad, texthist] = detect(url);
% removal(seg, segnum, between, label, near, centroids, url, grad, texthist);

function shadow_gui

    % Create main GUI window with professional styling
    fig = figure('Name', 'Shadow Detection and Removal System - prepared by nsanur', ...
                'Position', [50 50 1400 800], ...
                'Color', [0.15 0.15 0.15], ...
                'MenuBar', 'none', ...
                'ToolBar', 'none');

    % Create top control panel
    panel = uipanel('Parent', fig, ...
                   'Position', [0.02 0.85 0.96 0.13], ...
                   'BackgroundColor', [0.2 0.2 0.2], ...
                   'ForegroundColor', 'white', ...
                   'Title', 'Control Panel', ...
                   'FontSize', 12, ...
                   'FontWeight', 'bold');

    % Modern button styling
    btnProps = {'Parent', panel, 'Style', 'pushbutton', ...
               'BackgroundColor', [0.3 0.4 0.6], ...
               'ForegroundColor', 'white', ...
               'FontSize', 11, ...
               'FontWeight', 'bold'};
           
    uicontrol(btnProps{:}, ...
             'String', '📁 Select Image', ...
             'Position', [20 30 150 40], ...
             'Callback', @selectImage);
         
    uicontrol(btnProps{:}, ...
             'String', '🔍 Detect Shadow', ...
             'Position', [190 30 150 40], ...
             'Callback', @detectShadow);
         
    uicontrol(btnProps{:}, ...
             'String', '✨ Remove Shadow', ...
             'Position', [360 30 150 40], ...
             'Callback', @removeShadow);

    % Create image display area
    displayPanel = uipanel('Parent', fig, ...
                          'Position', [0.02 0.02 0.96 0.82], ...
                          'BackgroundColor', [0.15 0.15 0.15], ...
                          'ForegroundColor', 'white');

    % Create fixed subplot titles
    subplot(1,3,1, 'Parent', displayPanel);
    title('Original Image', 'Color', 'white', 'FontSize', 12, 'FontWeight', 'bold');
    axis off;
    
    subplot(1,3,2, 'Parent', displayPanel);
    title('Shadow Detection Result', 'Color', 'white', 'FontSize', 12, 'FontWeight', 'bold');
    axis off;
    
    subplot(1,3,3, 'Parent', displayPanel);
    title('Shadow Removal Result', 'Color', 'white', 'FontSize', 12, 'FontWeight', 'bold');
    axis off;

    % Global variables
    global imageData originalImage;
    imageData.filename = '';
    imageData.seg = [];
    imageData.segnum = [];
    imageData.between = [];
    imageData.near = [];
    imageData.centroids = [];
    imageData.label = [];
    imageData.grad = [];
    imageData.texthist = [];

    % Callback functions
    function selectImage(~, ~)
        % Open file selection dialog
        [filename, pathname] = uigetfile({'*.jpg;*.png;*.bmp', 'Image Files (*.jpg,*.png,*.bmp)'});
        
        % Check if a file was selected
        if filename ~= 0
            % Update the imageData structure with the new file path
            imageData.filename = fullfile(pathname, filename);
            originalImage = imread(imageData.filename);
    
            % Clear all previous panels and reset titles
            for i = 1:3
                subplot(1,3,i, 'Parent', displayPanel);
                cla;
                axis off;
            end
    
            % Display original image
            subplot(1,3,1, 'Parent', displayPanel);
            imshow(originalImage);
            title('Original Image', 'Color', 'white', 'FontSize', 12, 'FontWeight', 'bold');
            
            % Reset other panels with 'waiting' text centered
            subplot(1,3,2, 'Parent', displayPanel);
            title('Shadow Detection Result', 'Color', 'white', 'FontSize', 12, 'FontWeight', 'bold');
            text(0.5, 0.5, 'Waiting for detection...', 'Color', 'white', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
            axis([0 1 0 1]);  % Fix axis limits
    
            subplot(1,3,3, 'Parent', displayPanel);
            title('Shadow Removal Result', 'Color', 'white', 'FontSize', 12, 'FontWeight', 'bold');
            text(0.5, 0.5, 'Waiting for removal...', 'Color', 'white', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
            axis([0 1 0 1]);  % Fix axis limits

        end
    end

    function detectShadow(~, ~)
        if isempty(imageData.filename)
            msgbox('Please select an image first!', 'Warning');
            return;
        end
        
        % Update status
        subplot(1,3,2, 'Parent', displayPanel);
        cla;
        text(0.5, 0.5, 'Processing shadow detection...', 'Color', 'white', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
        axis([0 1 0 1]);  % Fix axis limits to keep text centered
        drawnow;
        
        % Add required libraries
        addpath('meanshift');
        addpath('libsvm/');
        addpath('./libsvm/matlab/');
        addpath('./etract_feature/');
        addpath('./utils/');
        
        % Detect shadows
        [imageData.seg, imageData.segnum, imageData.between, imageData.near, ...
         imageData.centroids, imageData.label, imageData.grad, imageData.texthist] = detect(imageData.filename);
        
        % Display shadow detection result
        subplot(1,3,2, 'Parent', displayPanel);
        imshow(imageData.label(imageData.seg));
        title('Shadow Detection Result', 'Color', 'white', 'FontSize', 12, 'FontWeight', 'bold');
    end
    
    function removeShadow(~, ~)
        if isempty(imageData.seg)
            msgbox('Please detect shadows first!', 'Warning');
            return;
        end
        
        % Update status
        subplot(1,3,3, 'Parent', displayPanel);
        cla;
        text(0.5, 0.5, 'Removing shadows...', 'Color', 'white', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
        axis([0 1 0 1]);  % Fix axis limits to keep text centered
        drawnow;
        
        % Remove shadows
        subplot(1,3,3, 'Parent', displayPanel);
        removal(imageData.seg, imageData.segnum, imageData.between, imageData.label, ...
                imageData.near, imageData.centroids, imageData.filename, ...
                imageData.grad, imageData.texthist);
        title('Shadow Removal Result', 'Color', 'white', 'FontSize', 12, 'FontWeight', 'bold');
    end
end