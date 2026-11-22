%% compare_mppt.m — compare P&O, IncCond and CV at 25 C and 50 C
pv_params;
boost_params;

names = {'P&O', 'IncCond', 'CV'};
temps = [25, 50];
t_step = 5.0;

for ti = 1:numel(temps)
    Tc = temps(ti);

    % update panel parameters in workspace for current temperature
    T = Tc + 273.15;
    Vt = Ns * n * k * T / q;
    Iph = (Isc_stc + Ki*(T - T_stc));   % G = 1000 W/m^2 (Step does 0.6*Iph)
    Voc_T = Voc_stc + Kv*(T - T_stc);
    I0 = (Isc_stc + Ki*(T - T_stc)) / (exp(Voc_T/Vt) - 1);

    Pmax1 = get_pmax(1000, Tc);
    Pmax2 = get_pmax(600, Tc);

    TP_all = cell(1,3);
    P_all  = cell(1,3);
    TD_all = cell(1,3);
    D_all  = cell(1,3);

    fprintf('\n=== Temperature T = %d C (Pmax: %.1f W -> %.1f W) ===\n', Tc, Pmax1, Pmax2);
    fprintf('Algo      | Eff(1000) | Eff(600) | Ripple D1 | Ripple D2 | t_settle\n');
    fprintf('-------------------------------------------------------------------\n');

    for m = 1:3
        algo_id = m;
        out = sim('boost_converter');

        tP = out.P_log.Time;
        P  = out.P_log.Data;
        tD = out.D_log.Time;
        D  = out.D_log.Data;

        TP_all{m} = tP;
        P_all{m}  = P;
        TD_all{m} = tD;
        D_all{m}  = D;

        wp1 = tP >= 2.0 & tP <= 4.8;
        wp2 = tP >= 7.0 & tP <= 9.8;
        wd1 = tD >= 2.0 & tD <= 4.8;
        wd2 = tD >= 7.0 & tD <= 9.8;

        eff1 = 100 * mean(P(wp1)) / Pmax1;
        eff2 = 100 * mean(P(wp2)) / Pmax2;

        rip1 = max(D(wd1)) - min(D(wd1));
        rip2 = max(D(wd2)) - min(D(wd2));

        % settling time (within 1% of Pmax2; NaN if never reaches MPP)
        idx = find(tP >= t_step);
        bad = find(abs(P(idx) - Pmax2) > 0.01 * Pmax2);
        if isempty(bad)
            t_set = 0;
        elseif bad(end) == numel(idx)
            t_set = NaN;
        else
            t_set = tP(idx(bad(end))) - t_step;
        end

        fprintf('%-9s | %8.2f%% | %7.2f%% | %9.4f | %9.4f | %6.3f s\n', ...
                names{m}, eff1, eff2, rip1, rip2, t_set);
    end

    %% plot for current temperature (light theme, 300 dpi export)
    fig = figure('Name', sprintf('MPPT comparison (%d C)', Tc), ...
        'Position', [100+40*ti 100 900 680]);
    theme(fig, 'light');

    subplot(3,1,1); hold on; grid on;
    for m = 1:3
        plot(TP_all{m}, P_all{m}, 'LineWidth', 1.4);
    end
    yline(Pmax1, '--k');
    yline(Pmax2, ':k');
    ylim([50 215]);
    ylabel('P, W');
    title(sprintf('PV Power at T = %d ^\\circC (G: 1000 \\rightarrow 600 W/m^2 at t = 5 s)', Tc));
    legend(names, 'Location', 'northeast');

    subplot(3,1,2); hold on; grid on;
    for m = 1:3
        plot(TD_all{m}, D_all{m}, 'LineWidth', 1.3);
    end
    ylim([0.05 0.55]);
    ylabel('D'); title('Duty cycle');

    subplot(3,1,3); hold on; grid on;
    for m = 1:3
        plot(TP_all{m}, P_all{m}, 'LineWidth', 1.5);
    end
    xlim([4.9 6.2]); ylim([50 205]);
    xlabel('t, s'); ylabel('P, W'); title('Step response zoom');

    if ~exist('../figures', 'dir'), mkdir('../figures'); end
    exportgraphics(fig, sprintf('../figures/mppt_%dC.png', Tc), 'Resolution', 300);
end

%% helper: theoretical Pmax from single-diode model
function Pmax = get_pmax(G, Tc)
    q = 1.602176634e-19;
    k = 1.380649e-23;
    Isc_stc = 8.21; Voc_stc = 32.9; Ns = 54;
    Ki = 0.0032; Kv = -0.1230;
    n = 1.3; Rs = 0.221; Rsh = 415.405;
    G_stc = 1000; T_stc = 25 + 273.15;

    T = Tc + 273.15;
    Vt = Ns * n * k * T / q;
    Iph = (Isc_stc + Ki*(T - T_stc)) * (G / G_stc);
    Voc_T = Voc_stc + Kv*(T - T_stc);
    I0 = (Isc_stc + Ki*(T - T_stc)) / (exp(Voc_T/Vt) - 1);

    V = linspace(0, 0.99*Voc_T, 500);
    I = zeros(size(V));
    for idx = 1:numel(V)
        i = Iph;
        for it = 1:100
            Vd = V(idx) + i*Rs;
            i_new = Iph - I0*(exp(Vd/Vt) - 1) - Vd/Rsh;
            if abs(i_new - i) < 1e-10, break; end
            i = i_new;
        end
        I(idx) = max(i, 0);
    end
    Pmax = max(V .* I);
end
