%% pv_dataset.m — generate (G, T, Vmp) dataset for ML-MPPT training
% Panel: KC200GT. Output: pv_dataset.csv

% constants
q = 1.602176634e-19;
k = 1.380649e-23;

% datasheet @ STC
Isc_stc = 8.21;
Voc_stc = 32.9;
Ns = 54;
Ki = 0.0032;
Kv = -0.1230;

% single-diode params
n   = 1.3;
Rs  = 0.221;
Rsh = 415.405;

% reference
G_stc = 1000;
T_stc = 25 + 273.15;

% sweep grid
G_list = 100:10:1000;      % W/m^2
T_list = 5:1:65;          % deg C

rows = [];

for G = G_list
    for Tc = T_list
        T = Tc + 273.15;

        Vt  = Ns * n * k * T / q;
        Iph = (Isc_stc + Ki*(T - T_stc)) * (G / G_stc);
        Voc_T = Voc_stc + Kv*(T - T_stc);
        I0  = (Isc_stc + Ki*(T - T_stc)) / (exp(Voc_T/Vt) - 1);

        % sweep V, find MPP
        V = linspace(0, 0.99*Voc_T, 400);
        I = zeros(size(V));
        for idx = 1:numel(V)
            i = Iph;
            for it = 1:100
                Vd = V(idx) + i*Rs;
                i_new = Iph - I0*(exp(Vd/Vt) - 1) - Vd/Rsh;
                if abs(i_new - i) < 1e-10, break; end
                i = i_new;
            end
            I(idx) = i;
        end
        I(I < 0) = 0;
        P = V .* I;
        [~, kmpp] = max(P);
        Vmp = V(kmpp);

        rows = [rows; G, Tc, Vmp];
    end
end

% save csv
T_out = array2table(rows, 'VariableNames', {'G','T','Vmp'});
writetable(T_out, 'pv_dataset.csv');

fprintf('done: %d rows -> pv_dataset.csv\n', size(rows,1));
fprintf('G: %d..%d W/m^2, T: %d..%d C\n', ...
        min(G_list), max(G_list), min(T_list), max(T_list));
