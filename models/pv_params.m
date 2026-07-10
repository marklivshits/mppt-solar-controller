%% pv_params.m — PV panel params (single-diode model), Kyocera KC200GT
% Run before simulation. Params: Villalva et al. 2009.

clear; clc;

% constants
q = 1.602176634e-19;
k = 1.380649e-23;

% datasheet @ STC
Isc_stc = 8.21;
Voc_stc = 32.9;
Imp_stc = 7.61;
Vmp_stc = 26.3;
Pmax_stc = Vmp_stc * Imp_stc;

Ns = 54;
Ki = 0.0032;      % A/K
Kv = -0.1230;     % V/K

% single-diode params
n   = 1.3;
Rs  = 0.221;
Rsh = 415.405;

% reference conditions
G_stc = 1000;
T_stc = 25 + 273.15;

% operating conditions
G = 1000;
T = 25 + 273.15;

% derived
Vt  = Ns * n * k * T / q;
Iph = (Isc_stc + Ki*(T - T_stc)) * (G / G_stc);
Voc_T = Voc_stc + Kv*(T - T_stc);
I0  = (Isc_stc + Ki*(T - T_stc)) / (exp(Voc_T/Vt) - 1);

% sanity check
fprintf('G = %.0f W/m^2, T = %.1f C\n', G, T - 273.15);
fprintf('Iph = %.4f A\n', Iph);
fprintf('I0  = %.4e A\n', I0);
fprintf('Vt  = %.4f V\n', Vt);
fprintf('expect: Isc ~ %.2f A, Voc ~ %.2f V, Pmax ~ %.1f W\n', ...
        Isc_stc, Voc_stc, Pmax_stc);
