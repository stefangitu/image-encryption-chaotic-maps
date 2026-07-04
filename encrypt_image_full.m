function encrypted_img = encrypt_image_full(img)
    % --- PASUL 1: Permutare Bogdanov ---
    k = 1; eps = 0; mu = 0; iteratii_bogdanov = 1;
    img_scrambled = bogdanov_scramble(img, k, eps, mu, iteratii_bogdanov);
    
    % --- PASUL 2: Calculul Semințelor (Sensibilitate la imagine) ---
    % Calculăm suma tuturor pixelilor pentru a genera cheile
    sum_pixels = sum(double(img(:)));
    Seed1 = mod(sum_pixels, 239) / 1000;
    Seed2 = mod(sum_pixels, 177) / 1000;
    
    % Corectăm parametrii Hărții Logistice (inversăm R cu x0 față de textul articolului)
    x01 = Seed1 + 0.392; R1 = 4;
    x02 = Seed2 + 0.628; R2 = 3.892;
    
    N = 2; % Numărul de iterații de criptare Tent
    Q = 100; % Timpul tranzitoriu (aruncăm primele 100 de valori)
    
    % --- PASUL 3: Generarea cheilor dinamice cu Harta Logistică ---
    x_log1 = zeros(1, Q + N); x_log1(1) = x01;
    x_log2 = zeros(1, Q + N); x_log2(1) = x02;
    
    for i = 1:(Q + N - 1)
        x_log1(i+1) = R1 * x_log1(i) * (1 - x_log1(i));
        x_log2(i+1) = R2 * x_log2(i) * (1 - x_log2(i));
    end
    
    % Păstrăm doar valorile de după regimul tranzitoriu
    tent_x0_array = x_log1(Q+1 : end);
    tent_p_array = x_log2(Q+1 : end);
    
    % --- PASUL 4: Difuzia cu Harta Tent ---
    [M, W, C] = size(img_scrambled);
    total_pixels = M * W * C;
    encrypted_img = img_scrambled;
    
    for iter = 1:N
        x0_tent = tent_x0_array(iter);
        p_tent = tent_p_array(iter);
        
        % Prealocăm secvența haotică pentru rapiditate
        tent_seq = zeros(total_pixels, 1);
        val = x0_tent;
        
        % Generăm secvența Tent pentru întreaga imagine
        for j = 1:total_pixels
            if val <= p_tent
                val = val / p_tent;
            else
                val = (1 - val) / (1 - p_tent);
            end
            tent_seq(j) = val;
        end
        
        % Convertim valorile zecimale (0,1) în valori întregi (0-255)
        tent_seq_uint8 = uint8(mod(floor(tent_seq * 10^10), 256));
        
        % Remodelăm secvența 1D într-o matrice 3D la fel ca imaginea
        tent_matrix_2d = reshape(tent_seq_uint8, M, W, C);
        
        % Aplicăm XOR între imagine și cheia haotică Tent
        encrypted_img = bitxor(encrypted_img, tent_matrix_2d);
    end
end