function decrypted_img = decrypt_image_full(encrypted_img, sum_pixels)
    % --- PASUL 1: Regenerarea cheilor (Logistic Map) ---
    % Folosim suma pixelilor primită ca "cheie secretă"
    Seed1 = mod(sum_pixels, 239) / 1000;
    Seed2 = mod(sum_pixels, 177) / 1000;
    
    x01 = Seed1 + 0.392; R1 = 4;
    x02 = Seed2 + 0.628; R2 = 3.892;
    
    N = 2; % Trebuie să fie la fel ca la criptare!
    Q = 100;
    
    x_log1 = zeros(1, Q + N); x_log1(1) = x01;
    x_log2 = zeros(1, Q + N); x_log2(1) = x02;
    
    for i = 1:(Q + N - 1)
        x_log1(i+1) = R1 * x_log1(i) * (1 - x_log1(i));
        x_log2(i+1) = R2 * x_log2(i) * (1 - x_log2(i));
    end
    
    tent_x0_array = x_log1(Q+1 : end);
    tent_p_array = x_log2(Q+1 : end);
    
    % --- PASUL 2: Decriptarea Difuziei (XOR invers) ---
    [M, W, C] = size(encrypted_img);
    total_pixels = M * W * C;
    img_unxor = encrypted_img;
    
    % Aplicăm XOR în ordine inversă
    for iter = N:-1:1
        x0_tent = tent_x0_array(iter);
        p_tent = tent_p_array(iter);
        
        tent_seq = zeros(total_pixels, 1);
        val = x0_tent;
        
        for j = 1:total_pixels
            if val <= p_tent
                val = val / p_tent;
            else
                val = (1 - val) / (1 - p_tent);
            end
            tent_seq(j) = val;
        end
        
        tent_seq_uint8 = uint8(mod(floor(tent_seq * 10^10), 256));
        tent_matrix_2d = reshape(tent_seq_uint8, M, W, C);
        
        % XOR recuperează valorile permutate
        img_unxor = bitxor(img_unxor, tent_matrix_2d);
    end
    
    % --- PASUL 3: Decriptarea Permutării (Bogdanov invers) ---
    k = 1; eps = 0; mu = 0; iteratii_bogdanov = 1;
    
    % Recreăm maparea directă pentru a o putea inversa
    [X, Y] = meshgrid(0:W-1, 0:M-1);
    for iter = 1:iteratii_bogdanov
        Y_new = mod(round(Y + eps.*Y + k.*X.*(X - 1) + mu.*X.*Y), M);
        X_new = mod(round(X + Y_new), W);
        X = X_new;
        Y = Y_new;
    end
    
    old_linear_indices = sub2ind([M, W], Y + 1, X + 1);
    new_linear_indices = 1:(M*W);
    
    decrypted_img = zeros(M, W, C, 'like', encrypted_img);
    
    for channel = 1:C
        current_channel = img_unxor(:, :, channel);
        dec_channel = zeros(M, W, 'like', current_channel);
        
        % INVERSĂM OPERAȚIA: punem pixelii din pozițiile noi înapoi în cele vechi
        dec_channel(new_linear_indices) = current_channel(old_linear_indices); % CORECT (Asta decriptează)
        decrypted_img(:, :, channel) = dec_channel;
    end
end