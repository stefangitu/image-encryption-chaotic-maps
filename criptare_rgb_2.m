% =====================================================================
%  CRIPTARE IMAGINI COLOR (RGB) CU SISTEME HAOTICE
%  Bogdanov (confuzie) + Logistica (generare chei) + Tent (difuzie)
%  Imagini standard MATLAB: peppers.png, saturn.png, autumn.tif, football.jpg
% =====================================================================
clc; clear; close all;

% >>>>>>>>>>>>>>>>>>>>>> MODIFICA AICI <<<<<<<<<<<<<<<<<<<<<<
img_file = 'football.jpg';
% >>>>>>>>>>>>>>>>>>>>>> SFARSIT MODIFICARI <<<<<<<<<<<<<<<<<

[~, img_name, ~] = fileparts(img_file);

% -- 1. Incarcare + verificare RGB + redimensionare 256x256 -----------
raw = imread(img_file);
if ndims(raw) ~= 3 || size(raw,3) ~= 3
    error('Imaginea "%s" nu este color RGB (3 canale).', img_file);
end
img = im2uint8(imresize(raw, [256 256]));
[M, N, C] = size(img);
fprintf('Imagine: %s | %dx%dx%d\n', img_file, M, N, C);

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

% -- 4. Entropie per canal + total (formula Shannon, inline) ----------
names = {'Rosu (R)','Verde (G)','Albastru (B)'};
H_enc = zeros(1,3);
fprintf('--- ENTROPIE [biti] ---\n%-14s %10s %10s\n','Canal','Original','Criptat');
fprintf('%s\n', repmat('-',1,36));
for ch = 1:3
    po = histcounts(double(img(:,:,ch)), 0:256); po = po(po>0)/numel(img(:,:,ch));
    pe = histcounts(double(enc(:,:,ch)), 0:256); pe = pe(pe>0)/numel(enc(:,:,ch));
    H_o = -sum(po .* log2(po));
    H_e = -sum(pe .* log2(pe));
    H_enc(ch) = H_e;
    fprintf('%-14s %10.4f %10.4f\n', names{ch}, H_o, H_e);
end
fprintf('%s\n', repmat('-',1,36));
pa = histcounts(double(img(:)), 0:256); pa = pa(pa>0)/numel(img);
pb = histcounts(double(enc(:)), 0:256); pb = pb(pb>0)/numel(enc);
fprintf('%-14s %10.4f %10.4f\n','TOTAL', -sum(pa.*log2(pa)), -sum(pb.*log2(pb)));
fprintf('%-14s %10s %10.4f\n\n','Ideal','-',8.0);

% -- 5. NPCR si UACI --------------------------------------------------
img2 = img;
img2(128,128,1) = uint8(mod(double(img(128,128,1))+1, 256));
enc2 = encrypt(img2);
Dmat = double(enc) ~= double(enc2);
NPCR = sum(Dmat(:)) / numel(Dmat) * 100;
UACI = sum(abs(double(enc(:)) - double(enc2(:)))) / (255*numel(enc)) * 100;
fprintf('NPCR = %.4f %% (ideal 99.6094%%)\n', NPCR);
fprintf('UACI = %.4f %% (ideal 33.4635%%)\n\n', UACI);

% -- 6. Corelatie H/V/D per canal (corrcoef, inline; fara grafic) -----
dirs = {'H','V','D'};
rng(42); np = 5000;
iH = randi([1 M],   np,1); jH = randi([1 N-1],np,1);
iV = randi([1 M-1], np,1); jV = randi([1 N],  np,1);
iD = randi([1 M-1], np,1); jD = randi([1 N-1],np,1);
Pa = {sub2ind([M N],iH,jH), sub2ind([M N],iV,jV),   sub2ind([M N],iD,jD)};
Pb = {sub2ind([M N],iH,jH+1), sub2ind([M N],iV+1,jV), sub2ind([M N],iD+1,jD+1)};
fprintf('--- CORELATIA PIXELILOR ADIACENTI ---\n');
fprintf('%-14s %10s %10s %10s\n','Canal / dir.', dirs{:});
fprintf('%s\n', repmat('-',1,48));
for ch = 1:3
    co = double(img(:,:,ch)); ce = double(enc(:,:,ch));
    r_o = zeros(1,3); r_e = zeros(1,3);
    for d = 1:3
        c1 = corrcoef(co(Pa{d}), co(Pb{d})); r_o(d) = c1(1,2);
        c2 = corrcoef(ce(Pa{d}), ce(Pb{d})); r_e(d) = c2(1,2);
    end
    fprintf('%-14s %+10.4f %+10.4f %+10.4f  (original)\n', names{ch}, r_o);
    fprintf('%-14s %+10.4f %+10.4f %+10.4f  (criptat)\n',  '',        r_e);
end
fprintf('\n');

% =====================================================================
%  FIGURA: imagini + histograme + entropie  (fara diferenta, fara corelatie)
% =====================================================================
c_rgb = {[0.85 0.10 0.10],[0.10 0.65 0.10],[0.10 0.10 0.85]};
figure('Name',['Criptare RGB - ' img_name],'Color','w','Position',[60 80 1280 620]);

% rand 1 - imagini + entropie
subplot(2,4,1); imshow(img); title('Original','FontWeight','bold');
subplot(2,4,2); imshow(enc); title('Criptat','FontWeight','bold');
subplot(2,4,3); imshow(dec); title('Decriptat','FontWeight','bold');
subplot(2,4,4);
b = bar(H_enc,'FaceColor','flat'); b.CData = [c_rgb{1}; c_rgb{2}; c_rgb{3}];
set(gca,'XTickLabel',{'R','G','B'}); ylim([7.5 8.05]);
yline(8,'--r','Ideal','LineWidth',1.2);
title('Entropie criptat / canal','FontWeight','bold'); ylabel('biti');

% rand 2 - histograme originale per canal + criptat suprapus
for ch = 1:3
    subplot(2,4,4+ch);
    histogram(double(reshape(img(:,:,ch),[],1)), 0:256, ...
        'FaceColor',c_rgb{ch},'EdgeColor','none');
    xlim([0 255]); title(['Hist. ' names{ch} ' - original'],'FontWeight','bold');
    xlabel('Intensitate'); ylabel('Frecventa');
end
subplot(2,4,8); hold on;
for ch = 1:3
    h = histcounts(double(reshape(enc(:,:,ch),[],1)), 0:256);
    plot(0:255, h, 'Color',c_rgb{ch}, 'LineWidth',1.2);
end
hold off; xlim([0 255]);
title('Histograme criptat (R/G/B)','FontWeight','bold');
xlabel('Intensitate'); ylabel('Frecventa'); legend({'R','G','B'},'Location','best');

sgtitle(sprintf('Criptare RGB - %s 256x256x3', ...
    [upper(img_name(1)) img_name(2:end)]), 'FontWeight','bold','FontSize',13);


% =====================================================================
%        FUNCTII PASTRATE: encrypt / decrypt / bogdanov
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
