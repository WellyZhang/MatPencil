function I = MatPencil(img, ks, width, dirNum, gammaS, gammaI, theta, pencil_stroke, sm_kr, group_num, avg_ks)
% ==============================================
% Pencil colorful sketch of the input image.
% Algorithm based on
%   Cewu Lu, Li Xu, Jiaya Jia 
%   /*Combining Sketch and Tone for Pencil Drawing Production*/ 
%   International Symposium on Non-Photorealistic Animation and Rendering(NPAR 2012)
%  
%  Paras:
%  img           : the input image.
%  ks            : the length of convolution line.
%  width         : the width of the stroke(must be odd).
%  dirNum        : the number of directions(the more the subtler.
%  gammaS        : the darkness of the stroke.
%  gammaI        : the darkness of the resulted image.
%  theta         : the regularizor parameter.
%  pencil_stroke : pencil stroke file path.
%  sm_kr         : smoothing kernel size for stroke generation.
%  group_num     : the group index for the parameter set of omegas.
%  avg_ks        : the kernel size for average filtering.
%

    %% Scale to image to [0, 1] while converting it to double precision 
    img = im2double(img);
    [~, ~, C] = size(img);

    %% Convert from RGB to YUV if the image is chromatic
    if (C == 3)
        yuv = rgb2ycbcr(img);
        Y = yuv(:, :, 1);
    else
        Y = img;
    end

    %% Get the stroke map
    S = get_stroke(Y, ks, width, dirNum, sm_kr) .^ gammaS; 
    % darken the result by gamma
    imwrite(S, 'outputs/demo_S.jpg');

    %% Get the tone map
    J = get_tone_map(Y, group_num, avg_ks) .^ gammaI; 
    % darken the result by gamma
    
    %% Get the pencil texture and convert it to grayscale
    P = im2double(imread(pencil_stroke));
    P = rgb2gray(P);

    %% Get the pencil map
    T = get_pencil(Y, P, J, theta);

    %% Compute the result
    new_Y = S .* T;

    if (C == 3)
        yuv(:, :, 1) = new_Y;
        I = ycbcr2rgb(yuv);
    else
        I = new_Y;
    end
end

function T = get_pencil(img, P, J, theta)
% ==============================================
%   Compute the pencil map
%  
%   Paras:
%   img   : input image in [0, 1].
%   P     : the pencil texture.
%   J     : the tone map.
%   theta : the regularizor parameter.
%

    %% Parameters
    [H, W, ~] = size(img);

    %% Initialization
    P = imresize(P, [H, W]);
    P = P(:);
    logP = log(P);
    logP = spdiags(logP, 0, H * W, H * W);
    
    J = imresize(J, [H, W]);
    J = J(:);
    logJ = log(J);
    
    e = ones(H*W, 1);
    Dx = spdiags([-e, e], [0, H], H * W, H * W);
    Dy = spdiags([-e, e], [0, 1], H * W, H * W);
    
    %% Compute matrix A and b for linear equation approximation
    A = theta * (Dx * Dx' + Dy * Dy') + (logP)' * logP;
    b = (logP)' * logJ;
    
    %% Conjugate gradient as the solver, pcg(A, b, tol, max_iter)
    beta = pcg(A, b, 1e-6, 100);
    
    %% Construct the result
    beta = reshape(beta, H, W);
    
    P = reshape(P, H, W);
    
    T = P .^ beta;
end

function S = get_stroke(img, ks, width, dirNum, sm_kr)
% ==============================================
%   Compute the stroke structure
%  
%   Paras:
%   img    : input image in [0, 1].
%   ks     : kernel size.
%   width  : width of the strocke
%   dirNum : number of directions.
%   sm_kr  : smoothing kernel size for stroke generation.
%
    
    %% Initialization
    [H, W, ~] = size(img);
    
    %% Median filter as smoothing 
    im = medfilt2(img, [sm_kr, sm_kr]);
    
    %% Image gradient
    imX = [abs(im(:, 1:(end-1)) - im(:, 2:end)), zeros(H, 1)];
    imY = [abs(im(1:(end-1), :) - im(2:end, :)); zeros(1, W)];  
    imEdge = imX + imY;

    %% Convolution kernel with horizontal direction 
    kerRef = zeros(ks * 2 + 1);
    kerRef(ks + 1,:) = 1;

    %% Classification 
    response = zeros(H, W, dirNum);
    for n = 1:dirNum
        ker = imrotate(kerRef, (n-1) * 180 / dirNum, 'bilinear', 'crop');
        response(:, :, n) = conv2(imEdge, ker, 'same');
    end

    [~, index] = max(response, [], 3); 

    %% Create the stroke
    C = zeros(H, W, dirNum);
    for n = 1:dirNum
        C(:, :, n) = imEdge .* (index == n);
    end

    kerRef = zeros(ks * 2 + 1);
    kerRef(ks + 1, :) = 1;
    width = (width - 1) / 2;
    kerRef((ks - width):(ks + width), :) = 1;
    
    Spn = zeros(H, W, dirNum);
    for n = 1:dirNum
        ker = imrotate(kerRef, (n - 1) * 180 / dirNum, 'bilinear', 'crop');
        Spn(:, :, n) = conv2(C(:, :, n), ker, 'same');
    end

    Sp = sum(Spn, 3);
    Sp = (Sp - min(Sp(:))) / (max(Sp(:)) - min(Sp(:)));
    S = 1 - Sp;
end

function J = get_tone_map(img, group_num, avg_ks)
% ==============================================
%   Compute the tone map 'T'
%  
%   Paras:
%   img       : input image ranging in[0, 1].
%   group_num : the group index for the parameter set of omegas.
%   avg_ks    : the kernel size for average filtering.
%
    
    %% Parameters
    Ub = 225;
    Ua = 105;
    Miud = 90;
    DeltaB = 9;
    DeltaD = 11;
    
    % groups from dark to light
    % 1st group
    if (group_num == 1)
        Omega1 = 42;
        Omega2 = 29;
        Omega3 = 29;
    end
    % 2nd group
    if (group_num == 2)
        Omega1 = 52;
        Omega2 = 37;
        Omega3 = 11;
    end
    % 3rd group
    if (group_num == 3)
        Omega1 = 76;
        Omega2 = 22;
        Omega3 = 2;
    end

    %% Compute the target histgram
    histgramTarget = zeros(256, 1);
    total = 0;
    for ii = 0:255
        if ii < Ua || ii > Ub
            p = 0;
        else
            p = 1 / (Ub - Ua);
        end
        
        histgramTarget(ii + 1, 1) = (...
            Omega1 * 1/DeltaB * exp(-(255 - ii) / DeltaB) + ...
            Omega2 * p + ...
            Omega3 * 1/sqrt(2 * pi * DeltaD) * exp(-(ii - Miud)^2 / (2 * DeltaD^2))) * 0.01;
        
        total = total + histgramTarget(ii + 1, 1);
    end
    histgramTarget(:, 1) = histgramTarget(:, 1)/total;
    
    %% Histgram matching
    J = histeq(img, histgramTarget);
    
    %% Smoothing
    G = fspecial('average', avg_ks);
    J = imfilter(J, G, 'same');
end