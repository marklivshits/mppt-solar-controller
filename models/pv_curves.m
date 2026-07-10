%% pv_curves.m — I-V and P-V curves for the single-diode model
% Run pv_params.m first.

pv_params;

V = linspace(0, Voc_stc, 500);
I = zeros(size(V));

% solve implicit eq. by fixed-point iteration
for idx = 1:numel(V)
    i = Iph;                     % initial guess
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

[Pmax, k_mpp] = max(P);
Vmp = V(k_mpp);
Imp = I(k_mpp);

fprintf('Pmax = %.2f W at Vmp = %.2f V, Imp = %.2f A\n', Pmax, Vmp, Imp);
fprintf('Vmp/Voc = %.3f\n', Vmp/Voc_stc);

%% plots
figure('Name','PV curves','Position',[100 100 900 400]);

subplot(1,2,1);
plot(V, I, 'LineWidth', 1.6); grid on; hold on;
plot(Vmp, Imp, 'ro', 'MarkerFaceColor', 'r');
xlabel('V, V'); ylabel('I, A'); title('I-V curve');
legend('I-V', 'MPP', 'Location', 'southwest');

subplot(1,2,2);
plot(V, P, 'LineWidth', 1.6); grid on; hold on;
plot(Vmp, Pmax, 'ro', 'MarkerFaceColor', 'r');
xlabel('V, V'); ylabel('P, W'); title('P-V curve');
legend('P-V', 'MPP', 'Location', 'northwest');
