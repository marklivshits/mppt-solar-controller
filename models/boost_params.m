%% boost_params.m — boost converter params (averaged model)
%  Vin ~ Vmp of panel, Vout target = 48 V.

% target operating point
Vout_ref = 48;        % V, desired output
Vin_nom  = 26.3;      % V, panel Vmp (nominal)

% component values
L = 1e-3;             % H, inductor
C = 470e-6;           % F, output capacitor
fs = 20e3;            % Hz, switching freq (ref only, averaged model)

% load (battery side)
R_load = Vout_ref^2 / 200;   % Ohm, ~matched to 200 W
Iload = Vout_ref / R_load;   % A

% initial duty cycle (approx, MPPT will drive it later)
D0 = 1 - Vin_nom/Vout_ref;   % ~0.45

fprintf('D0 ~ %.3f\n', D0);
fprintf('R_load = %.2f Ohm, Iload = %.2f A\n', R_load, Iload);
