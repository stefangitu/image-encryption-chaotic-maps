% =====================================================================
%  CRIPTARE IMAGINI GRAYSCALE CU SISTEME HAOTICE
%  Bogdanov (confuzie) + Logistica (generare chei) + Tent (difuzie).
%  Imagini standard MATLAB: cameraman.tif, rice.png, liftingbody.png
%  (sau orice imagine; daca e color, se converteste automat in grayscale).
% =====================================================================
clc; clear; close all;

% >>>>>>>>>>>>>>>>>>>>>> MODIFICA AICI <<<<<<<<<<<<<<<<<<<<<<
img_file = 'peppers.png';
% >>>>>>>>>>>>>>>>>>>>>> SFARSIT MODIFICARI <<<<<<<<<<<<<<<<<

[~, img_name, ~] = fileparts(img_file);

% -- 1. Incarcare + grayscale + redimensionare 256x256 ----------------
raw = imread(img_file);
if ndims(raw) == 3 && size(raw,3) == 3
    raw = rgb2gray(raw);            % color -> grayscale
end
img = im2uint8(imresize(raw, [256 256]));
[M, N] = size(img);
fprintf('Imagine: %s | %dx%d (grayscale)\n', img_file, M, N);

% -- 2. Criptare + decriptare -----------------------------------------
tic; enc = encrypt(img);  t_enc = toc;
S = sum(double(img(:)));
tic; dec = decrypt(enc, S); t_dec = toc;
fprintf('Timp criptare: %.2f ms | decriptare: %.2f ms\n', t_enc*1000, t_dec*1000);

% -- 3. PSNR ----------------------------------------------------------
MSE = mean((double(img(:)) - double(dec(:))).^2);
if MSE == 0
    fprintf('PSNR = INF  ->  reconstructie PERFECTA (MSE = 0)\n\n');
else
    fprintf('PSNR = %.4f dB  (MSE = %.4g)\n\n', 10*log10(255^2/MSE), MSE);
end

% -- 4. Entropie (formula Shannon, inline) ----------------------------
po = histcounts(double(img(:)), 0:256); po = po(po>0)/numel(img);
pe = histcounts(double(enc(:)), 0:256); pe = pe(pe>0)/numel(enc);
H_orig = -sum(po .* log2(po));
H_enc  = -sum(pe .* log2(pe));
fprintf('--- ENTROPIE [biti] ---\n');
fprintf('%-14s %10.4f\n','Original', H_orig);
fprintf('%-14s %10.4f\n','Criptat',  H_enc);
fprintf('%-14s %10.4f\n\n','Ideal',   8.0);

% -- 5. NPCR si UACI --------------------------------------------------
img2 = img;
img2(128,128) = uint8(mod(double(img(128,128))+1, 256));
enc2 = encrypt(img2);
Dmat = double(enc) ~= double(enc2);
NPCR = sum(Dmat(:)) / numel(Dmat) * 100;
UACI = sum(abs(double(enc(:)) - double(enc2(:)))) / (255*numel(enc)) * 100;
fprintf('NPCR = %.4f %% (ideal 99.6094%%)\n', NPCR);
fprintf('UACI = %.4f %% (ideal 33.4635%%)\n\n', UACI);

% -- 6. Corelatie H/V/D (corrcoef, inline; fara grafic) ---------------
rng(42); np = 5000;
iH = randi([1 M],   np,1); jH = randi([1 N-1],np,1);
iV = randi([1 M-1], np,1); jV = randi([1 N],  np,1);
iD = randi([1 M-1], np,1); jD = randi([1 N-1],np,1);
Pa = {sub2ind([M N],iH,jH), sub2ind([M N],iV,jV),   sub2ind([M N],iD,jD)};
Pb = {sub2ind([M N],iH,jH+1), sub2ind([M N],iV+1,jV), sub2ind([M N],iD+1,jD+1)};
co = double(img); ce = double(enc);
r_o = zeros(1,3); r_e = zeros(1,3);
for d = 1:3
    c1 = corrcoef(co(Pa{d}), co(Pb{d})); r_o(d) = c1(1,2);
    c2 = corrcoef(ce(Pa{d}), ce(Pb{d})); r_e(d) = c2(1,2);
end
fprintf('--- CORELATIA PIXELILOR ADIACENTI ---\n');
fprintf('%-14s %10s %10s %10s\n','', 'H','V','D');
fprintf('%s\n', repmat('-',1,48));
fprintf('%-14s %+10.4f %+10.4f %+10.4f\n','Original', r_o);
fprintf('%-14s %+10.4f %+10.4f %+10.4f\n\n','Criptat', r_e);

% =====================================================================
%  FIGURA: imagini + histograme  (fara diferenta, fara corelatie)
% =====================================================================
col_orig = [0.00 0.45 0.74];   % albastru
col_enc  = [0.85 0.33 0.10];   % caramiziu
figure('Name',['Criptare grayscale - ' img_name],'Color','w','Position',[60 100 1180 620]);

subplot(2,3,1); imshow(img); title('Original','FontWeight','bold');
subplot(2,3,2); imshow(enc); title('Criptat','FontWeight','bold');
subplot(2,3,3); imshow(dec); title('Decriptat','FontWeight','bold');

subplot(2,3,4);
histogram(double(img(:)), 0:256, 'FaceColor',col_orig,'EdgeColor','none');
xlim([0 255]); xlabel('Intensitate'); ylabel('Frecventa');
title(sprintf('Hist. original (H=%.4f)', H_orig),'FontWeight','bold');

subplot(2,3,5);
histogram(double(enc(:)), 0:256, 'FaceColor',col_enc,'EdgeColor','none');
xlim([0 255]); xlabel('Intensitate'); ylabel('Frecventa');
title(sprintf('Hist. criptat (H=%.4f)', H_enc),'FontWeight','bold');

subplot(2,3,6); hold on;
plot(0:255, histcounts(double(img(:)),0:256), 'Color',col_orig, 'LineWidth',1.4);
plot(0:255, histcounts(double(enc(:)),0:256), 'Color',col_enc,  'LineWidth',1.4);
hold off; xlim([0 255]); xlabel('Intensitate'); ylabel('Frecventa');
title('Histograme suprapuse','FontWeight','bold');
legend({'Original','Criptat'},'Location','best');

sgtitle(sprintf('Criptare grayscale - %s 256x256', ...
    [upper(img_name(1)) img_name(2:end)]), 'FontWeight','bold','FontSize',13);


% =====================================================================
%        FUNCTII PASTRATE: encrypt / decrypt / bogdanov
%   (identice cu cele din scriptul RGB; trateaza nativ C=1 grayscale)
% =====================================================================
function enc = encrypt(img)
    [M, N, C] = size(img);
    k = 1; epsv = 0; mu = 0; iteratii = 1;

    % --- Confuzie: permutarea Bogdanov ---
    perm = bogdanov(M, N, k, epsv, mu, iteratii);
    scr = zeros(M, N, C, 'like', img);
    for ch = 1:C
        chan = img(:,:,ch);
        s = zeros(M, N, 'like', chan);
        s(perm) = chan(:);
        scr(:,:,ch) = s;
    end

    % --- Generarea cheilor (Logistica) ---
    S = sum(double(img(:)));
    x01 = mod(S, 239)/1000 + 0.392; R1 = 4;
    x02 = mod(S, 177)/1000 + 0.628; R2 = 3.892;
    Nk = 2; Q = 100;
    a = zeros(1, Q+Nk); a(1) = x01;
    bb = zeros(1, Q+Nk); bb(1) = x02;
    for i = 1:(Q+Nk-1)
        a(i+1)  = R1 * a(i)  * (1 - a(i));
        bb(i+1) = R2 * bb(i) * (1 - bb(i));
    end
    tent_x0 = a(Q+1:end);
    tent_p  = bb(Q+1:end);

    % --- Difuzie: XOR multi-runda cu secventa Tent ---
    T = M * N * C;
    enc = scr;
    for it = 1:Nk
        x0 = tent_x0(it); p = tent_p(it);
        seq = zeros(T, 1); v = x0;
        for j = 1:T
            if v <= p, v = v / p; else, v = (1 - v) / (1 - p); end
            seq(j) = v;
        end
        key = reshape(uint8(mod(floor(seq * 1e10), 256)), M, N, C);
        enc = bitxor(enc, key);
    end
end

function dec = decrypt(enc, S)
    [M, N, C] = size(enc);
    k = 1; epsv = 0; mu = 0; iteratii = 1;

    % --- Regenerarea cheilor (Logistica), identic cu criptarea ---
    x01 = mod(S, 239)/1000 + 0.392; R1 = 4;
    x02 = mod(S, 177)/1000 + 0.628; R2 = 3.892;
    Nk = 2; Q = 100;
    a = zeros(1, Q+Nk); a(1) = x01;
    bb = zeros(1, Q+Nk); bb(1) = x02;
    for i = 1:(Q+Nk-1)
        a(i+1)  = R1 * a(i)  * (1 - a(i));
        bb(i+1) = R2 * bb(i) * (1 - bb(i));
    end
    tent_x0 = a(Q+1:end);
    tent_p  = bb(Q+1:end);

    % --- Difuzie inversa: XOR in ordine inversa ---
    T = M * N * C;
    unx = enc;
    for it = Nk:-1:1
        x0 = tent_x0(it); p = tent_p(it);
        seq = zeros(T, 1); v = x0;
        for j = 1:T
            if v <= p, v = v / p; else, v = (1 - v) / (1 - p); end
            seq(j) = v;
        end
        key = reshape(uint8(mod(floor(seq * 1e10), 256)), M, N, C);
        unx = bitxor(unx, key);
    end

    % --- Inversarea permutarii Bogdanov ---
    perm = bogdanov(M, N, k, epsv, mu, iteratii);
    dec = zeros(M, N, C, 'like', enc);
    for ch = 1:C
        s = unx(:,:,ch);
        rec = zeros(M, N, 'like', s);
        rec(:) = s(perm);
        dec(:,:,ch) = rec;
    end
end

function perm = bogdanov(M, N, k, epsv, mu, iteratii)
    % Genereaza permutarea bidimensionala a hartii Bogdanov.
    [X, Y] = meshgrid(0:N-1, 0:M-1);
    for it = 1:iteratii
        Y = mod(round(Y + epsv.*Y + k.*X.*(X-1) + mu.*X.*Y), M);
        X = mod(round(X + Y), N);
    end
    perm = sub2ind([M, N], Y+1, X+1);
    perm = perm(:);
    if numel(unique(perm)) ~= M*N
        error(['Permutarea Bogdanov NU este bijectiva (M=%d, N=%d). ', ...
               'Foloseste o imagine patrata (M=N) sau alti parametri.'], M, N);
    end
end
