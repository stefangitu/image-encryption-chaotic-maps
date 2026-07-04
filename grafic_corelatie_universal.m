% =========================================================
% GRAFICE CORELATIE PIXELI ADIACENTI (H, V, D)
% =========================================================

clc; close all;

% 
img_file = 'peppers.png';   % numele imaginii
mode     = 'gray';          % 'gray' | 'R' | 'G' | 'B'
% 

% -- 1. Incarca imaginea si extrage canalul dorit ---------
img_raw = imread(img_file);
[~, img_name, ~] = fileparts(img_file);

switch mode
    case 'gray'
        if size(img_raw,3)==3, img_proc = rgb2gray(img_raw); else, img_proc = img_raw; end
        ch_label = 'grayscale';   suffix = 'gs';
    case 'R'
        img_proc = img_raw(:,:,1); ch_label = 'canal R'; suffix = 'R';
    case 'G'
        img_proc = img_raw(:,:,2); ch_label = 'canal G'; suffix = 'G';
    case 'B'
        img_proc = img_raw(:,:,3); ch_label = 'canal B'; suffix = 'B';
end
img_proc  = imresize(img_proc, [256 256]);
save_file = ['corel_' img_name '_' suffix '.png'];   % nume generat AUTOMAT
[M, N] = size(img_proc);
fprintf('Imagine: %s (%s)  |  %dx%d\n', img_file, ch_label, M, N);

% -- 2. Cripteaza -----------------------------------------
encrypted = encrypt_image_full(img_proc);

% -- 3. Selecteaza 5000 perechi aleatoare -----------------
rng(42); np = 5000;
ri_h = randi([1,M],   np,1); rj_h = randi([1,N-1], np,1);
ri_v = randi([1,M-1], np,1); rj_v = randi([1,N],   np,1);
ri_d = randi([1,M-1], np,1); rj_d = randi([1,N-1], np,1);

xo_h = double(img_proc(sub2ind([M,N], ri_h, rj_h)));   yo_h = double(img_proc(sub2ind([M,N], ri_h,   rj_h+1)));
xo_v = double(img_proc(sub2ind([M,N], ri_v, rj_v)));   yo_v = double(img_proc(sub2ind([M,N], ri_v+1, rj_v)));
xo_d = double(img_proc(sub2ind([M,N], ri_d, rj_d)));   yo_d = double(img_proc(sub2ind([M,N], ri_d+1, rj_d+1)));
xe_h = double(encrypted(sub2ind([M,N], ri_h, rj_h)));  ye_h = double(encrypted(sub2ind([M,N], ri_h,   rj_h+1)));
xe_v = double(encrypted(sub2ind([M,N], ri_v, rj_v)));  ye_v = double(encrypted(sub2ind([M,N], ri_v+1, rj_v)));
xe_d = double(encrypted(sub2ind([M,N], ri_d, rj_d)));  ye_d = double(encrypted(sub2ind([M,N], ri_d+1, rj_d+1)));

% -- 4. Coeficienti de corelatie --------------------------
r_oh = calc_r(xo_h,yo_h); r_eh = calc_r(xe_h,ye_h);
r_ov = calc_r(xo_v,yo_v); r_ev = calc_r(xe_v,ye_v);
r_od = calc_r(xo_d,yo_d); r_ed = calc_r(xe_d,ye_d);
fprintf('\n--- COEFICIENTI DE CORELATIE ---\n');
fprintf('             Original      Criptat\n');
fprintf('Orizontala:  %9.6f   %10.6f\n', r_oh, r_eh);
fprintf('Verticala:   %9.6f   %10.6f\n', r_ov, r_ev);
fprintf('Diagonala:   %9.6f   %10.6f\n', r_od, r_ed);

% -- 5. Grafice profesionale (300 DPI) --------------------
dir_names = {'Orizontala','Verticala','Diagonala'};
xo = {xo_h,xo_v,xo_d}; yo = {yo_h,yo_v,yo_d};
xe = {xe_h,xe_v,xe_d}; ye = {ye_h,ye_v,ye_d};
r_orig_v = [r_oh,r_ov,r_od]; r_enc_v = [r_eh,r_ev,r_ed];
col_orig = [0.00 0.45 0.74];  col_enc = [0.85 0.33 0.10];

fig = figure('Name',['Corelatie - ' img_name],'Position',[30 30 1500 950],'Color','w');
for col = 1:3
    ax1 = subplot(2,3,col);
    scatter(xo{col},yo{col},6,col_orig,'filled','MarkerFaceAlpha',0.35,'MarkerEdgeColor','none');
    axis([0 255 0 255]); axis square; grid on; box on;
    set(ax1,'FontName','Times New Roman','FontSize',11,'GridAlpha',0.15,'XTick',0:50:250,'YTick',0:50:250);
    xlabel('Valoare pixel (i, j)','FontSize',11); ylabel('Valoare pixel adiacent','FontSize',11);
    title({sprintf('%s \x2013 Original', dir_names{col}), sprintf('r = %.4f', r_orig_v(col))}, ...
          'FontName','Times New Roman','FontSize',12,'FontWeight','bold');

    ax2 = subplot(2,3,col+3);
    scatter(xe{col},ye{col},6,col_enc,'filled','MarkerFaceAlpha',0.30,'MarkerEdgeColor','none');
    axis([0 255 0 255]); axis square; grid on; box on;
    set(ax2,'FontName','Times New Roman','FontSize',11,'GridAlpha',0.15,'XTick',0:50:250,'YTick',0:50:250);
    xlabel('Valoare pixel (i, j)','FontSize',11); ylabel('Valoare pixel adiacent','FontSize',11);
    title({sprintf('%s \x2013 Criptat', dir_names{col}), sprintf('r = %.6f', r_enc_v(col))}, ...
          'FontName','Times New Roman','FontSize',12,'FontWeight','bold');
end

% Titlu (cu numele imaginii capitalizat corect)
nice_name = [upper(img_name(1)), img_name(2:end)];
sgtitle(sprintf('Corelatia pixelilor adiacenti \x2013 %s (%s) 256\x00D7256', nice_name, ch_label), ...
        'FontName','Times New Roman','FontSize',14,'FontWeight','bold');

exportgraphics(fig, save_file, 'Resolution', 300);
fprintf('\nGrafic salvat: %s\n', save_file);

% -- Functie locala ---------------------------------------
function r = calc_r(x,y)
    x=double(x(:)); y=double(y(:));
    mx=mean(x); my=mean(y);
    r=sum((x-mx).*(y-my))/sqrt(sum((x-mx).^2)*sum((y-my).^2));
end
