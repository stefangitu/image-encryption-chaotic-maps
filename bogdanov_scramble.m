function scrambled_img = bogdanov_scramble(img, k, eps, mu, iterations)
    % Verificăm dimensiunile imaginii
    [M, N, C] = size(img);
    scrambled_img = zeros(M, N, C, 'like', img);
    
    % Generăm coordonatele inițiale ale tuturor pixelilor
    % Trecem de la 1-based (specific MATLAB) la 0-based pentru calcule matematice
    [X, Y] = meshgrid(0:N-1, 0:M-1);
    
    % Aplicăm ecuațiile Bogdanov pentru numărul dorit de iterații
    for iter = 1:iterations
        % Calculăm noile coordonate y_{n+1} și x_{n+1}
        % Folosim funcția 'mod' pentru a menține pixelii în interiorul imaginii
        Y_new = mod(round(Y + eps.*Y + k.*X.*(X - 1) + mu.*X.*Y), M);
        X_new = mod(round(X + Y_new), N);
        
        X = X_new;
        Y = Y_new;
    end
    
    % Transformăm matricile de coordonate 2D în indecși liniari 1D 
    % Adăugăm +1 pentru a reveni la indexarea de la 1 din MATLAB
    old_linear_indices = sub2ind([M, N], Y + 1, X + 1);
    new_linear_indices = 1:(M*N);
    
    % Mapăm pixelii pe noile poziții, canal cu canal (dacă e imagine color C=3, dacă e grayscale C=1)
    for channel = 1:C
        current_channel = img(:, :, channel);
        scrambled_channel = zeros(M, N, 'like', current_channel);
        
        % Vectorizarea operației de rearanjare (aici câștigăm timpul de execuție)
        scrambled_channel(old_linear_indices) = current_channel(new_linear_indices);
        scrambled_img(:, :, channel) = scrambled_channel;
    end
end