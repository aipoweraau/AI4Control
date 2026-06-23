% function out = calc_metrics_one_run(CA1, Te, ia)
% % calc_metrics_one_run(CA, Te, ia)
% % CA : 1x1 double (0/1/2)
% % Te : struct with fields .time, .signals.values
% % ia : struct with fields .time, .signals.values
% % Writes OS_*, ST_*, THD_* into base workspace and returns a struct out.
% 
% % ---- A) Identify algorithm ----
% 
% % CA_val = round(double(CA));
% % switch CA_val
% %     case 0, tag = "PI";
% %     case 1, tag = "MPC";
% %     case 2, tag = "DPC";
% %     otherwise
% %         error('CA must be 0/1/2, current=%g', CA_val);
% % end
% 
% 
% %%debug
% 
%  % 添加调试信息
%     fprintf('=== calc_metrics_one_run called ===\n');
%     fprintf('Input CA1 type: %s\n', class(CA1));
% 
%     if isstruct(CA1)
%         fprintf('CA1 is struct with fields: %s\n', strjoin(fieldnames(CA1), ', '));
%         if isfield(CA1, 'signals')
%             fprintf('CA1.signals.values size: %s\n', mat2str(size(CA1.signals.values)));
%             fprintf('CA1.signals.values end value: %g\n', CA1.signals.values(end));
%         end
%     end
% 
% 
% 
% CA=CA1;
% % % ---- Robust CA extraction: CA can be double OR struct ----
% % if isnumeric(CA)
% %     CA_val = round(double(CA));
% % 
% % elseif isstruct(CA) && isfield(CA,'signals') && isfield(CA.signals,'values')
% %     v = CA.signals.values;
% %     v = v(:);
% %     CA_val = round(double(v(end)));
% % 
% % else
% %     error('Unsupported CA type. class(CA) = %s', class(CA));
% % end
% 
% %%
% CA = CA1;
% 
% if isnumeric(CA)
%     CA_val = round(double(CA));
% 
% elseif isstruct(CA) && isfield(CA, 'signals')
%     % CA.signals可能是结构体
%     if isstruct(CA.signals) && isfield(CA.signals, 'values')
%         v = CA.signals.values;
%         v = v(:);
%         CA_val = round(double(v(end)));
%     elseif isnumeric(CA.signals)
%         % 如果CA.signals直接是数值
%         v = CA.signals;
%         v = v(:);
%         CA_val = round(double(v(end)));
%     else
%         error('无法从CA结构体中提取数值');
%     end
% 
% else
%     error('Unsupported CA type. class(CA) = %s', class(CA));
% end
% 
% %%
% 
% switch CA_val
%     case 0, tag = "PI";
%     case 1, tag = "MPC";
%     case 2, tag = "DPC";
%     otherwise
%         error('CA must be 0/1/2, current = %g', CA_val);
% end
% 
% % ---- B) Overshoot + Settling time from Te ----
% t0       = 3.0;
% ref      = 1.0;
% tol      = 0.05;
% t_delay  = 0.002;
% epsEnter = 0.03;
% Tw_peak  = 0.60;
% 
% t = Te.time(:);
% y = Te.signals.values;
% y = squeeze(y);
% if size(y,2) > 1, y = y(:,1); end
% y = y(:);
% 
% [~, idx] = sort(t);
% t = t(idx); y = y(idx);
% 
% tStart = t0 + t_delay;
% idxA = t >= tStart;
% tA = t(idxA); yA = y(idxA);
% 
% enterBand = epsEnter * abs(ref);
% kEnter = find(abs(yA - ref) <= enterBand, 1, 'first');
% if isempty(kEnter)
%     error('Te never enters ref±epsEnter after step. Increase epsEnter or check ref/t0.');
% end
% t_enter = tA(kEnter);
% 
% idxPeak = (t >= t_enter) & (t <= t_enter + Tw_peak);
% y_peak_window = max(y(idxPeak));
% OS_pct = max(0, (y_peak_window - ref)/abs(ref)*100);
% 
% band = tol * abs(ref);
% idxSet = t >= t_enter;
% tS = t(idxSet); yS = y(idxSet);
% 
% inBand = abs(yS - ref) <= band;
% kLastOut = find(~inBand, 1, 'last');
% if isempty(kLastOut)
%     ST = 0;
% elseif kLastOut == numel(tS)
%     ST = NaN;
% else
%     ST = tS(kLastOut+1) - t0;
% end
% 
% % ---- C) THD from ia ----
% t1 = 3.5;
% t2 = 3.8;
% 
% rpm = 1200;
% pn  = 4;
% f0  = pn * (rpm/60);
% 
% useHann  = false;
% removeDC = true;
% 
% tt = ia.time(:);
% xx = ia.signals.values;
% xx = squeeze(xx);
% if size(xx,2) > 1, xx = xx(:,1); end
% xx = xx(:);
% 
% idxW = (tt >= t1) & (tt <= t2);
% tw = tt(idxW);
% xw = xx(idxW);
% 
% if numel(xw) < 8
%     error('FFT window too short or data too sparse: N=%d', numel(xw));
% end
% 
% Ts = mean(diff(tw));
% fs = 1/Ts;
% 
% if removeDC, xw = xw - mean(xw); end
% 
% N = length(xw);
% w = ones(N,1);
% if useHann, w = hann(N); end
% 
% X = fft(xw .* w);
% 
% f = (0:N-1) * (fs/N);
% N2 = floor(N/2)+1;
% f1 = f(1:N2);
% X1 = X(1:N2);
% 
% df = fs/N;
% 
% if useHann
%     scale = sum(w)/2;
%     mag1 = abs(X1)/scale;
% else
%     mag1 = 2*abs(X1)/N;
%     mag1(1) = mag1(1)/2;
% end
% 
% k1 = round(f0/df) + 1;
% k1 = max(2, min(k1, length(mag1)));
% V1 = mag1(k1);
% 
% H = 40;
% Vh2 = 0;
% for h = 2:H
%     kh = round(h*f0/df) + 1;
%     if kh <= length(mag1)
%         Vh2 = Vh2 + mag1(kh)^2;
%     end
% end
% THD_pct = sqrt(Vh2)/max(V1,1e-12) * 100;
% 
% % ---- D) Save to base workspace ----
% assignin('base', "OS_"  + tag, OS_pct);
% assignin('base', "ST_"  + tag, ST);
% assignin('base', "THD_" + tag, THD_pct);
% 
% % optional: structured store
% if evalin('base','exist(''Results'',''var'')')
%     Results = evalin('base','Results');
%     if ~isstruct(Results), Results = struct(); end
% else
%     Results = struct();
% end
% Results.(tag).OS  = OS_pct;
% Results.(tag).ST  = ST;
% Results.(tag).THD = THD_pct;
% Results.(tag).Te  = Te;
% Results.(tag).ia  = ia;
% assignin('base','Results',Results);
% 
% out = struct('tag',tag,'CA',CA_val,'OS',OS_pct,'ST',ST,'THD',THD_pct,'f0',f0);
% end



function out = calc_metrics_one_run(CA1, Te, ia)
% calc_metrics_one_run(CA1, Te, ia)
% CA1 : 1x1 double (0/1/2) OR struct with .signals.values
% Te  : struct with fields .time, .signals.values  (electromagnetic torque)
% ia  : struct with fields .time, .signals.values  (phase-a current)
% Writes OS_*, ST_*, THD_* into base workspace and returns a struct out.

%% ============================================================
%  A) Identify algorithm by CA
%% ============================================================
fprintf('=== calc_metrics_one_run called ===\n');
fprintf('Input CA1 type: %s\n', class(CA1));

if isnumeric(CA1)
    CA_val = round(double(CA1));

elseif isstruct(CA1) && isfield(CA1, 'signals')
    if isstruct(CA1.signals) && isfield(CA1.signals, 'values')
        v = CA1.signals.values;
    elseif isnumeric(CA1.signals)
        v = CA1.signals;
    else
        error('Cannot extract value from CA1 struct.');
    end
    v = v(:);
    CA_val = round(double(v(end)));
else
    error('Unsupported CA1 type: %s', class(CA1));
end

switch CA_val
    case 0, tag = "PI";
    case 1, tag = "MPC";
    case 2, tag = "DPC";
    otherwise
        error('CA must be 0/1/2, current = %g', CA_val);
end

fprintf('Algorithm identified: %s\n', tag);

%% ============================================================
%  B) Overshoot + Settling time from Te
%% ============================================================
% --- Parameters ---
t0       = 3.0;    % step occurrence time (s)
ref      = 1.0;    % reference value after step
tol      = 0.05;   % settling band: ±5%
t_delay  = 0.002;  % skip initial delay after step (s)
epsEnter = 0.03;   % neighbourhood threshold to detect signal arrival: ±3%
Tw_peak  = 0.60;   % search window for overshoot after t_enter (s)

% --- Read and clean Te signal ---
t = Te.time(:);
y = Te.signals.values;
y = squeeze(y);
if size(y,2) > 1, y = y(:,1); end
y = y(:);

[~, idx] = sort(t);
t = t(idx);
y = y(idx);

% --- Start search after delay ---
tStart = t0 + t_delay;

% --- Step 1: find t_enter (first time signal enters ref ± epsEnter) ---
idxA = t >= tStart;
tA = t(idxA);
yA = y(idxA);

enterBand = epsEnter * abs(ref);
kEnter = find(abs(yA - ref) <= enterBand, 1, 'first');
if isempty(kEnter)
    error(['Te never enters ref±%.0f%% band after t0+t_delay.\n' ...
           'Check: ref=%.2f, t0=%.2f, epsEnter=%.2f'], ...
           epsEnter*100, ref, t0, epsEnter);
end
t_enter = tA(kEnter);

% --- Step 2: Overshoot ---
% Search from tStart (not t_enter) to capture peaks before signal settles
% Use t_enter + Tw_peak as the end of the search window
idxPeak = (t >= tStart) & (t <= t_enter + Tw_peak);
if ~any(idxPeak)
    OS_pct = 0;
else
    y_peak = max(y(idxPeak));
    OS_pct = max(0, (y_peak - ref) / abs(ref) * 100);
end

% --- Step 3: Settling time ---
% Search from tStart (not t_enter) to avoid missing early oscillations
band = tol * abs(ref);
% idxSet = t >= tStart;
% tS = t(idxSet);
% yS = y(idxSet);
% 
% inBand    = abs(yS - ref) <= band;
% kLastOut  = find(~inBand, 1, 'last');
% 
% if isempty(kLastOut)
%     % Signal never left the band after tStart — settled immediately
%     ST = 0;
% elseif kLastOut == numel(tS)
%     % Signal still outside band at end of simulation
%     ST = NaN;
%     warning('ST_%s: signal did not settle within simulation time.', tag);
% else
%     % ST = time of last exit from band, measured from t0
%     ST = tS(kLastOut + 1) - t0;


% --- Step 1: find t_enter ---
idxA = t >= tStart;
tA = t(idxA);
yA = y(idxA);

enterBand = epsEnter * abs(ref);
kEnter = find(abs(yA - ref) <= enterBand, 1, 'first');
if isempty(kEnter)
    error('Te never enters ref±%.0f%% band.', epsEnter*100);
end
t_enter = tA(kEnter);

% --- Step 2: Overshoot (from tStart to t_enter + Tw_peak) ---
idxPeak = (t >= tStart) & (t <= t_enter + Tw_peak);
if ~any(idxPeak)
    OS_pct = 0;
else
    y_peak = max(y(idxPeak));
    OS_pct = max(0, (y_peak - ref) / abs(ref) * 100);
end

% --- Step 3: Settling time (from t_enter, not tStart) ---
band = tol * abs(ref);
idxSet = t >= t_enter;      % <-- 关键：从 t_enter 开始
tS = t(idxSet);
yS = y(idxSet);

inBand   = abs(yS - ref) <= band;
kLastOut = find(~inBand, 1, 'last');

if isempty(kLastOut)
    ST = t_enter - t0;      % 进入就稳定了
elseif kLastOut == numel(tS)
    ST = NaN;
    warning('ST_%s: did not settle within simulation time.', tag);
else
    ST = tS(kLastOut+1) - t0;

end

%% ============================================================
%  C) THD from ia (FFT over window [t1, t2])
%% ============================================================
t1 = 3.5;   % FFT window start (s)
t2 = 3.8;   % FFT window end   (s)

rpm = 1200;
pn  = 4;
f0  = pn * (rpm / 60);   % electrical fundamental frequency (Hz)

useHann  = false;
removeDC = true;

% --- Read and clean ia signal ---
tt = ia.time(:);
xx = ia.signals.values;
xx = squeeze(xx);
if size(xx,2) > 1, xx = xx(:,1); end
xx = xx(:);

idxW = (tt >= t1) & (tt <= t2);
tw   = tt(idxW);
xw   = xx(idxW);

if numel(xw) < 8
    error('FFT window too short (N=%d). Check t1/t2 or simulation length.', numel(xw));
end

Ts = mean(diff(tw));
fs = 1 / Ts;

if removeDC
    xw = xw - mean(xw);
end

N = length(xw);
w = ones(N, 1);
if useHann, w = hann(N); end

X  = fft(xw .* w);
f  = (0:N-1) * (fs / N);
N2 = floor(N/2) + 1;
f1 = f(1:N2);
X1 = X(1:N2);
df = fs / N;

% Magnitude scaling (rectangular window)
if useHann
    scale = sum(w) / 2;
    mag1  = abs(X1) / scale;
else
    mag1     = 2 * abs(X1) / N;
    mag1(1)  = mag1(1) / 2;   % DC bin: no ×2
end

% Fundamental bin
k1 = round(f0 / df) + 1;
k1 = max(2, min(k1, length(mag1)));
V1 = mag1(k1);

% Sum harmonic power (2nd to Hth order)
H    = 40;
Vh2  = 0;
for h = 2:H
    kh = round(h * f0 / df) + 1;
    if kh <= length(mag1)
        Vh2 = Vh2 + mag1(kh)^2;
    end
end
THD_pct = sqrt(Vh2) / max(V1, 1e-12) * 100;

%% ============================================================
%  D) Save results to base workspace
%% ============================================================
assignin('base', "OS_"  + tag, OS_pct);
assignin('base', "ST_"  + tag, ST);
assignin('base', "THD_" + tag, THD_pct);

% Structured storage in Results struct
if evalin('base', "exist('Results','var')")
    Results = evalin('base', 'Results');
    if ~isstruct(Results), Results = struct(); end
else
    Results = struct();
end

Results.(tag).OS  = OS_pct;
Results.(tag).ST  = ST;
Results.(tag).THD = THD_pct;
Results.(tag).Te  = Te;
Results.(tag).ia  = ia;
assignin('base', 'Results', Results);

%% ============================================================
%  E) Print summary
%% ============================================================
fprintf('\n====== Algorithm: %s (CA=%d) ======\n', tag, CA_val);
fprintf('Overshoot     (OS_%s)  = %.3f %%\n',  tag, OS_pct);
if isnan(ST)
    fprintf('Settling Time (ST_%s)  = NaN  (did not settle)\n', tag);
else
    fprintf('Settling Time (ST_%s)  = %.6f s\n', tag, ST);
end
fprintf('THD           (THD_%s) = %.3f %%\n',  tag, THD_pct);
fprintf('=====================================\n\n');

%% ============================================================
%  F) Return struct
%% ============================================================
out = struct('tag', tag, 'CA', CA_val, ...
             'OS',  OS_pct, 'ST', ST, 'THD', THD_pct, 'f0', f0);
end