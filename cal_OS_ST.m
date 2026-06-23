% %% ========= 0) Settings (match powergui) =========
% t1 = 3.5;
% t2 = 3.8;
% 
% rpm = 1200;
% pn  = 4;                 % 极对数
% f0  = pn * (rpm/60);     % electrical fundamental = 80 Hz
% 
% useHann = false;         % powergui 默认更像 rectangular（不加窗）
% removeDC = true;         % powergui FFT 一般会自动处理直流/你也可以关掉对比
% 
% %% ========= 1) Extract from "structure with time" =========
% t = ia.time(:);
% x = ia.signals.values;
% 
% % 如果是多列，选第一列
% if size(x,2) > 1
%     x = x(:,1);
% end
% x = x(:);
% 
% % window 3–3.2s
% idx = (t >= t1) & (t <= t2);
% tw = t(idx);
% xw = x(idx);
% 
% % sampling freq
% Ts = mean(diff(tw));
% fs = 1/Ts;
% 
% % remove DC
% if removeDC
%     xw = xw - mean(xw);
% end
% 
% %% ========= 2) FFT (match powergui style) =========
% N = length(xw);
% 
% % windowing
% if useHann
%     w = hann(N);
% else
%     w = ones(N,1);   % rectangular
% end
% 
% xwin = xw .* w;
% X = fft(xwin);
% 
% % frequency axis
% f = (0:N-1) * (fs/N);
% 
% % single-sided
% N2 = floor(N/2)+1;
% f1 = f(1:N2);
% X1 = X(1:N2);
% 
% % amplitude-like normalization:
% % Rectangular: peak amplitude approx = 2*|X|/N (single-sided)
% % Hann: use sum(w) normalization
% if useHann
%     scale = sum(w)/2;
%     mag1 = abs(X1) / scale;
% else
%     mag1 = 2*abs(X1)/N;
%     mag1(1) = mag1(1)/2;  % DC不要乘2
% end
% 
% %% ========= 3) Pick harmonics and compute THD =========
% % find bin closest to fundamental
% df = fs/N;
% k1 = round(f0/df) + 1;
% V1 = mag1(k1);
% 
% H = 40;   % harmonic order
% Vh2 = 0;
% for h = 2:H
%     kh = round(h*f0/df) + 1;
%     if kh <= length(mag1)
%         Vh2 = Vh2 + mag1(kh)^2;
%     end
% end
% THD_percent = sqrt(Vh2)/V1 * 100;
% 
% %% ========= 4) Plot =========
% figure('Color','w');
% plot(f1, mag1, 'LineWidth', 1.2); grid on;
% xlabel('Frequency (Hz)'); ylabel('Magnitude (peak approx)');
% title(sprintf('FFT window %.1f–%.1fs | f0=%.1f Hz | THD=%.2f%%', t1,t2,f0,THD_percent));
% xlim([0 1000]);
% 
% % mark fundamental
% hold on;
% stem(f1(k1), mag1(k1), 'LineWidth', 1.5);
% text(f1(k1), mag1(k1), sprintf('  f0=%.1fHz', f0), 'VerticalAlignment','bottom');
% 
% %% ========= 5) Print summary =========
% fprintf('\n=== FFT check (%.1f–%.1f s) ===\n', t1,t2);
% fprintf('fs = %.3f Hz, N = %d, df = %.6f Hz\n', fs, N, df);
% fprintf('Fundamental f0 = %.3f Hz (bin %.0f -> %.3f Hz)\n', f0, k1, f1(k1));
% fprintf('V1 (peak approx) = %.6f\n', V1);
% fprintf('THD (2..%d) = %.3f %%\n\n', H, THD_percent);



%% ============================================================
%  A) Identify algorithm by CA
%% ============================================================
% ===== Robust extraction for CA (struct with time) =====
% %% ========= 0) Settings (match powergui) =========
% t1 = 3.5;
% t2 = 3.8;
% 
% rpm = 1200;
% pn  = 4;                 % 极对数
% f0  = pn * (rpm/60);     % electrical fundamental = 80 Hz
% 
% useHann = false;         % powergui 默认更像 rectangular（不加窗）
% removeDC = true;         % powergui FFT 一般会自动处理直流/你也可以关掉对比
% 
% %% ========= 1) Extract from "structure with time" =========
% t = ia.time(:);
% x = ia.signals.values;
% 
% % 如果是多列，选第一列
% if size(x,2) > 1
%     x = x(:,1);
% end
% x = x(:);
% 
% % window 3–3.2s
% idx = (t >= t1) & (t <= t2);
% tw = t(idx);
% xw = x(idx);
% 
% % sampling freq
% Ts = mean(diff(tw));
% fs = 1/Ts;
% 
% % remove DC
% if removeDC
%     xw = xw - mean(xw);
% end
% 
% %% ========= 2) FFT (match powergui style) =========
% N = length(xw);
% 
% % windowing
% if useHann
%     w = hann(N);
% else
%     w = ones(N,1);   % rectangular
% end
% 
% xwin = xw .* w;
% X = fft(xwin);
% 
% % frequency axis
% f = (0:N-1) * (fs/N);
% 
% % single-sided
% N2 = floor(N/2)+1;
% f1 = f(1:N2);
% X1 = X(1:N2);
% 
% % amplitude-like normalization:
% % Rectangular: peak amplitude approx = 2*|X|/N (single-sided)
% % Hann: use sum(w) normalization
% if useHann
%     scale = sum(w)/2;
%     mag1 = abs(X1) / scale;
% else
%     mag1 = 2*abs(X1)/N;
%     mag1(1) = mag1(1)/2;  % DC不要乘2
% end
% 
% %% ========= 3) Pick harmonics and compute THD =========
% % find bin closest to fundamental
% df = fs/N;
% k1 = round(f0/df) + 1;
% V1 = mag1(k1);
% 
% H = 40;   % harmonic order
% Vh2 = 0;
% for h = 2:H
%     kh = round(h*f0/df) + 1;
%     if kh <= length(mag1)
%         Vh2 = Vh2 + mag1(kh)^2;
%     end
% end
% THD_percent = sqrt(Vh2)/V1 * 100;
% 
% %% ========= 4) Plot =========
% figure('Color','w');
% plot(f1, mag1, 'LineWidth', 1.2); grid on;
% xlabel('Frequency (Hz)'); ylabel('Magnitude (peak approx)');
% title(sprintf('FFT window %.1f–%.1fs | f0=%.1f Hz | THD=%.2f%%', t1,t2,f0,THD_percent));
% xlim([0 1000]);
% 
% % mark fundamental
% hold on;
% stem(f1(k1), mag1(k1), 'LineWidth', 1.5);
% text(f1(k1), mag1(k1), sprintf('  f0=%.1fHz', f0), 'VerticalAlignment','bottom');
% 
% %% ========= 5) Print summary =========
% fprintf('\n=== FFT check (%.1f–%.1f s) ===\n', t1,t2);
% fprintf('fs = %.3f Hz, N = %d, df = %.6f Hz\n', fs, N, df);
% fprintf('Fundamental f0 = %.3f Hz (bin %.0f -> %.3f Hz)\n', f0, k1, f1(k1));
% fprintf('V1 (peak approx) = %.6f\n', V1);
% fprintf('THD (2..%d) = %.3f %%\n\n', H, THD_percent);



%% ============================================================
%  A) Identify algorithm by CA
%% ============================================================
% ===== Robust extraction for CA (struct with time) =====
CA_val = round(double(CA));   % CA 是 1x1 double


switch CA_val
    case 0, tag = "PI";
    case 1, tag = "MPC";
    case 2, tag = "DPC";
    otherwise
        error('CA must be 0/1/2, current = %g', CA_val);
end



%% ============================================================
%  B) Overshoot + Settling time from Te (struct with time)
%% ============================================================
% ---- Inputs you used ----
t0      = 3.0;      % step time
ref     = 1.0;      % new steady reference after step
tol     = 0.05;     % 5% band (for settling)
t_delay = 0.002;    % ignore command-effective delay
epsEnter = 0.03;    % enter ref neighborhood to start counting overshoot
Tw_peak = 0.60;     % peak window length after entering neighborhood

% ---- Read from Te (struct with time format) ----
t = Te.time(:);
y = Te.signals.values;
if size(y,2) > 1
    y = y(:,1);  % 如果多列，取第一列
end
y = y(:);

[~, order] = sort(t); 
t = t(order); 
y = y(order);

% ---- start after delay ----
tStart = t0 + t_delay;
idxA = t >= tStart;
tA = t(idxA);  
yA = y(idxA);

% ---- find "enter neighborhood" time (avoid counting the falling edge) ----
enterBand = epsEnter * abs(ref);
kEnter = find(abs(yA - ref) <= enterBand, 1, 'first');
if isempty(kEnter)
    error('Never enters ref±epsEnter band after t0+t_delay. Increase epsEnter or check ref/t0.');
end
t_enter = tA(kEnter);

% ---- Overshoot only after entering neighborhood ----
idxPeak = (t >= t_enter) & (t <= t_enter + Tw_peak);
y_peak_window = max(y(idxPeak));
OS_pct = max(0, (y_peak_window - ref)/abs(ref)*100);

% ---- Settling time (classic: stay within ±5% band afterwards) ----
band = tol * abs(ref);
idxSet = t >= t_enter;
tS = t(idxSet); 
yS = y(idxSet);

inBand = abs(yS - ref) <= band;
kLastOut = find(~inBand, 1, 'last');
if isempty(kLastOut)
    ST = 0;            % already always within band
elseif kLastOut == numel(tS)
    ST = NaN;          % never settles by end of sim
else
    ST = tS(kLastOut+1) - t0;  % relative to step time t0
end

%% ============================================================
%  C) THD from ia struct (window t1-t2)
%% ============================================================
t1 = 3.5;   % FFT window start
t2 = 3.8;   % FFT window end

rpm = 1200;
pn  = 4;                 % pole pairs
f0  = pn * (rpm/60);     % electrical fundamental

useHann  = false;        % powergui often like rectangular unless specified
removeDC = true;

% ---- Extract from struct with time ----
tt = ia.time(:);
xx = ia.signals.values;
if size(xx,2) > 1
    xx = xx(:,1);
end
xx = xx(:);

idx = (tt >= t1) & (tt <= t2);
tw = tt(idx);
xw = xx(idx);

if numel(xw) < 8
    error('FFT window too short or data too sparse: N=%d', numel(xw));
end

Ts = mean(diff(tw));
fs = 1/Ts;

if removeDC
    xw = xw - mean(xw);
end

N = length(xw);
if useHann
    w = hann(N);
else
    w = ones(N,1);
end

xwin = xw .* w;
X = fft(xwin);

f = (0:N-1) * (fs/N);
N2 = floor(N/2)+1;
f1 = f(1:N2);
X1 = X(1:N2);

df = fs/N;

% ---- magnitude scaling (keep your current style) ----
if useHann
    scale = sum(w)/2;
    mag1 = abs(X1) / scale;
else
    mag1 = 2*abs(X1)/N;
    mag1(1) = mag1(1)/2;
end

% ---- THD (2..H) ----
k1 = round(f0/df) + 1;
k1 = max(2, min(k1, length(mag1)));   % guard
V1 = mag1(k1);

H = 40;
Vh2 = 0;
for h = 2:H
    kh = round(h*f0/df) + 1;
    if kh <= length(mag1)
        Vh2 = Vh2 + mag1(kh)^2;
    end
end

THD_pct = sqrt(Vh2)/max(V1,1e-12) * 100;

%% ============================================================
%  D) Save by algorithm name (both struct + individual vars)
%% ============================================================
% ---- recommended structured storage ----
if ~exist('Results','var') || ~isstruct(Results)
    Results = struct();
end
Results.(tag).OS  = OS_pct;
Results.(tag).ST  = ST;
Results.(tag).THD = THD_pct;
Results.(tag).Te  = Te;   % 保存完整的Te数据
Results.(tag).ia  = ia;   % 保存完整的ia数据

% ---- variables like OS_PI, ST_PI, THD_PI ----
assignin('base', "OS_"  + tag, OS_pct);
assignin('base', "ST_"  + tag, ST);
assignin('base', "THD_" + tag, THD_pct);

fprintf('\n====== Algorithm: %s (CA=%d) ======\n', tag, CA_val);
fprintf('Overshoot (OS_%s)  = %.3f%%\n', tag, OS_pct);
fprintf('Settling Time (ST_%s) = %.6f s\n', tag, ST);
fprintf('THD (THD_%s)       = %.3f%%\n', tag, THD_pct);
fprintf('=====================================\n\n');

%% ============================================================
%  E) Optional: Quick visualization
%% ============================================================
% Uncomment if you want to see plots for each algorithm
% figure('Color','w','Name',sprintf('%s - Te Response',tag));
% plot(t-t0, y, 'LineWidth', 1.2); grid on; hold on;
% yline(ref, 'k--', 'ref');
% yline(ref*(1+tol), 'r:', '+5%');
% yline(ref*(1-tol), 'r:', '-5%');
% xline(t_enter-t0, 'g-.', 'enter band');
% if ~isnan(ST)
%     xline(ST, 'm-.', 'settling');
% end
% title(sprintf('%s: OS=%.2f%%, ST=%.4fs', tag, OS_pct, ST));
% xlabel('Time after step (s)'); ylabel('Te (N*m)');
% 
% figure('Color','w','Name',sprintf('%s - ia FFT',tag));
% plot(f1, mag1, 'LineWidth', 1.2); grid on;
% xlabel('Frequency (Hz)'); ylabel('Magnitude');
% title(sprintf('%s: THD=%.2f%%', tag, THD_pct));
% xlim([0 1000]);
% hold on;
% stem(f1(k1), mag1(k1), 'r', 'LineWidth', 1.5);
% text(f1(k1), mag1(k1), sprintf('  f0=%.1fHz', f0), 'VerticalAlignment','bottom');


% %% ============================================================
% %  B) Overshoot + Settling time from Te (struct with time)
% %% ============================================================
% % ---- Inputs you used ----
% t0      = 3.0;      % step time
% ref     = 1.0;      % new steady reference after step
% tol     = 0.02;     % 2% band (for settling) - 修改这里，从0.05改为0.02
% t_delay = 0.002;    % ignore command-effective delay
% epsEnter = 0.03;    % enter ref neighborhood to start counting overshoot
% Tw_peak = 0.60;     % peak window length after entering neighborhood
% 
% % ---- Read from Te (struct with time format) ----
% t = Te.time(:);
% y = Te.signals.values;
% if size(y,2) > 1
%     y = y(:,1);  % 如果多列，取第一列
% end
% y = y(:);
% 
% [~, order] = sort(t); 
% t = t(order); 
% y = y(order);
% 
% % ---- start after delay ----
% tStart = t0 + t_delay;
% idxA = t >= tStart;
% tA = t(idxA);  
% yA = y(idxA);
% 
% % ---- find "enter neighborhood" time (avoid counting the falling edge) ----
% enterBand = epsEnter * abs(ref);
% kEnter = find(abs(yA - ref) <= enterBand, 1, 'first');
% if isempty(kEnter)
%     error('Never enters ref±epsEnter band after t0+t_delay. Increase epsEnter or check ref/t0.');
% end
% t_enter = tA(kEnter);
% 
% % ---- Overshoot only after entering neighborhood ----
% idxPeak = (t >= t_enter) & (t <= t_enter + Tw_peak);
% y_peak_window = max(y(idxPeak));
% OS_pct = max(0, (y_peak_window - ref)/abs(ref)*100);
% 
% % ---- Settling time (classic: stay within ±2% band afterwards) ----
% band = tol * abs(ref);  % 现在是 ±2%
% idxSet = t >= t_enter;
% tS = t(idxSet); 
% yS = y(idxSet);
% 
% inBand = abs(yS - ref) <= band;
% kLastOut = find(~inBand, 1, 'last');
% if isempty(kLastOut)
%     ST = 0;            % already always within band
% elseif kLastOut == numel(tS)
%     ST = NaN;          % never settles by end of sim
% else
%     ST = tS(kLastOut+1) - t0;  % relative to step time t0
% end
% 
% %% ============================================================
% %  C) THD from ia struct (window t1-t2)
% %% ============================================================
% t1 = 3.5;   % FFT window start
% t2 = 3.8;   % FFT window end
% 
% rpm = 1200;
% pn  = 4;                 % pole pairs
% f0  = pn * (rpm/60);     % electrical fundamental
% 
% useHann  = false;        % powergui often like rectangular unless specified
% removeDC = true;
% 
% % ---- Extract from struct with time ----
% tt = ia.time(:);
% xx = ia.signals.values;
% if size(xx,2) > 1
%     xx = xx(:,1);
% end
% xx = xx(:);
% 
% idx = (tt >= t1) & (tt <= t2);
% tw = tt(idx);
% xw = xx(idx);
% 
% if numel(xw) < 8
%     error('FFT window too short or data too sparse: N=%d', numel(xw));
% end
% 
% Ts = mean(diff(tw));
% fs = 1/Ts;
% 
% if removeDC
%     xw = xw - mean(xw);
% end
% 
% N = length(xw);
% if useHann
%     w = hann(N);
% else
%     w = ones(N,1);
% end
% 
% xwin = xw .* w;
% X = fft(xwin);
% 
% f = (0:N-1) * (fs/N);
% N2 = floor(N/2)+1;
% f1 = f(1:N2);
% X1 = X(1:N2);
% 
% df = fs/N;
% 
% % ---- magnitude scaling (keep your current style) ----
% if useHann
%     scale = sum(w)/2;
%     mag1 = abs(X1) / scale;
% else
%     mag1 = 2*abs(X1)/N;
%     mag1(1) = mag1(1)/2;
% end
% 
% % ---- THD (2..H) ----
% k1 = round(f0/df) + 1;
% k1 = max(2, min(k1, length(mag1)));   % guard
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
% 
% THD_pct = sqrt(Vh2)/max(V1,1e-12) * 100;
% 
% %% ============================================================
% %  D) Save by algorithm name (both struct + individual vars)
% %% ============================================================
% % ---- recommended structured storage ----
% if ~exist('Results','var') || ~isstruct(Results)
%     Results = struct();
% end
% Results.(tag).OS  = OS_pct;
% Results.(tag).ST  = ST;
% Results.(tag).THD = THD_pct;
% Results.(tag).Te  = Te;   % 保存完整的Te数据
% Results.(tag).ia  = ia;   % 保存完整的ia数据
% 
% % ---- variables like OS_PI, ST_PI, THD_PI ----
% assignin('base', "OS_"  + tag, OS_pct);
% assignin('base', "ST_"  + tag, ST);
% assignin('base', "THD_" + tag, THD_pct);
% 
% fprintf('\n====== Algorithm: %s (CA=%d) ======\n', tag, CA_val);
% fprintf('Overshoot (OS_%s)  = %.3f%%\n', tag, OS_pct);
% fprintf('Settling Time (ST_%s, ±2%%) = %.6f s\n', tag, ST);  % 添加说明
% fprintf('THD (THD_%s)       = %.3f%%\n', tag, THD_pct);
% fprintf('=====================================\n\n');


switch CA_val
    case 0, tag = "PI";
    case 1, tag = "MPC";
    case 2, tag = "DPC";
    otherwise
        error('CA must be 0 (PI), 1 (MPC), 2 (DPC). Current CA=%g', CA_val);
end


%% ============================================================
%  B) Overshoot + Settling time from Te (struct with time)
%% ============================================================
% ---- Inputs you used ----
t0      = 3.0;      % step time
ref     = 1.0;      % new steady reference after step
tol     = 0.05;     % 5% band (for settling)
t_delay = 0.002;    % ignore command-effective delay
epsEnter = 0.03;    % enter ref neighborhood to start counting overshoot
Tw_peak = 0.60;     % peak window length after entering neighborhood

% ---- Read from Te (struct with time format) ----
assert(exist('Te','var')==1, 'Te not found');

t = Te.time(:);
y = Te.signals.values;

y = squeeze(y);            % 防止 3D
if size(y,2) > 1
    y = y(:,1);
end
y = y(:);

[~, idx] = sort(t);
t = t(idx);
y = y(idx);


% ---- start after delay ----
tStart = t0 + t_delay;
idxA = t >= tStart;
tA = t(idxA);  
yA = y(idxA);

% ---- find "enter neighborhood" time (avoid counting the falling edge) ----
enterBand = epsEnter * abs(ref);
kEnter = find(abs(yA - ref) <= enterBand, 1, 'first');
if isempty(kEnter)
    error('Never enters ref±epsEnter band after t0+t_delay. Increase epsEnter or check ref/t0.');
end
t_enter = tA(kEnter);

% ---- Overshoot only after entering neighborhood ----
idxPeak = (t >= t_enter) & (t <= t_enter + Tw_peak);
y_peak_window = max(y(idxPeak));
OS_pct = max(0, (y_peak_window - ref)/abs(ref)*100);

% ---- Settling time (classic: stay within ±5% band afterwards) ----
band = tol * abs(ref);
idxSet = t >= t_enter;
tS = t(idxSet); 
yS = y(idxSet);

inBand = abs(yS - ref) <= band;
kLastOut = find(~inBand, 1, 'last');
if isempty(kLastOut)
    ST = 0;            % already always within band
elseif kLastOut == numel(tS)
    ST = NaN;          % never settles by end of sim
else
    ST = tS(kLastOut+1) - t0;  % relative to step time t0
end

%% ============================================================
%  C) THD from ia struct (window t1-t2)
%% ============================================================
t1 = 3.5;   % FFT window start
t2 = 3.8;   % FFT window end

rpm = 1200;
pn  = 4;                 % pole pairs
f0  = pn * (rpm/60);     % electrical fundamental

useHann  = false;        % powergui often like rectangular unless specified
removeDC = true;

% ---- Extract from struct with time ----
assert(exist('ia','var')==1, 'ia not found');

tt = ia.time(:);
xx = ia.signals.values;

xx = squeeze(xx);
if size(xx,2) > 1
    xx = xx(:,1);
end
xx = xx(:);

if size(xx,2) > 1
    xx = xx(:,1);
end
xx = xx(:);

idx = (tt >= t1) & (tt <= t2);
tw = tt(idx);
xw = xx(idx);

if numel(xw) < 8
    error('FFT window too short or data too sparse: N=%d', numel(xw));
end

Ts = mean(diff(tw));
fs = 1/Ts;

if removeDC
    xw = xw - mean(xw);
end

N = length(xw);
if useHann
    w = hann(N);
else
    w = ones(N,1);
end

xwin = xw .* w;
X = fft(xwin);

f = (0:N-1) * (fs/N);
N2 = floor(N/2)+1;
f1 = f(1:N2);
X1 = X(1:N2);

df = fs/N;

% ---- magnitude scaling (keep your current style) ----
if useHann
    scale = sum(w)/2;
    mag1 = abs(X1) / scale;
else
    mag1 = 2*abs(X1)/N;
    mag1(1) = mag1(1)/2;
end

% ---- THD (2..H) ----
k1 = round(f0/df) + 1;
k1 = max(2, min(k1, length(mag1)));   % guard
V1 = mag1(k1);

H = 40;
Vh2 = 0;
for h = 2:H
    kh = round(h*f0/df) + 1;
    if kh <= length(mag1)
        Vh2 = Vh2 + mag1(kh)^2;
    end
end

THD_pct = sqrt(Vh2)/max(V1,1e-12) * 100;

%% ============================================================
%  D) Save by algorithm name (both struct + individual vars)
%% ============================================================
% ---- recommended structured storage ----
if ~exist('Results','var') || ~isstruct(Results)
    Results = struct();
end
Results.(tag).OS  = OS_pct;
Results.(tag).ST  = ST;
Results.(tag).THD = THD_pct;
Results.(tag).Te  = Te;   % 保存完整的Te数据
Results.(tag).ia  = ia;   % 保存完整的ia数据

% ---- variables like OS_PI, ST_PI, THD_PI ----
assignin('base', "OS_"  + tag, OS_pct);
assignin('base', "ST_"  + tag, ST);
assignin('base', "THD_" + tag, THD_pct);

fprintf('\n====== Algorithm: %s (CA=%d) ======\n', tag, CA_val);
fprintf('Overshoot (OS_%s)  = %.3f%%\n', tag, OS_pct);
fprintf('Settling Time (ST_%s) = %.6f s\n', tag, ST);
fprintf('THD (THD_%s)       = %.3f%%\n', tag, THD_pct);
fprintf('=====================================\n\n');

%% ============================================================
%  E) Optional: Quick visualization
%% ============================================================
% Uncomment if you want to see plots for each algorithm
% figure('Color','w','Name',sprintf('%s - Te Response',tag));
% plot(t-t0, y, 'LineWidth', 1.2); grid on; hold on;
% yline(ref, 'k--', 'ref');
% yline(ref*(1+tol), 'r:', '+5%');
% yline(ref*(1-tol), 'r:', '-5%');
% xline(t_enter-t0, 'g-.', 'enter band');
% if ~isnan(ST)
%     xline(ST, 'm-.', 'settling');
% end
% title(sprintf('%s: OS=%.2f%%, ST=%.4fs', tag, OS_pct, ST));
% xlabel('Time after step (s)'); ylabel('Te (N*m)');
% 
% figure('Color','w','Name',sprintf('%s - ia FFT',tag));
% plot(f1, mag1, 'LineWidth', 1.2); grid on;
% xlabel('Frequency (Hz)'); ylabel('Magnitude');
% title(sprintf('%s: THD=%.2f%%', tag, THD_pct));
% xlim([0 1000]);
% hold on;
% stem(f1(k1), mag1(k1), 'r', 'LineWidth', 1.5);
% text(f1(k1), mag1(k1), sprintf('  f0=%.1fHz', f0), 'VerticalAlignment','bottom');


% %% ============================================================
% %  B) Overshoot + Settling time from Te (struct with time)
% %% ============================================================
% % ---- Inputs you used ----
% t0      = 3.0;      % step time
% ref     = 1.0;      % new steady reference after step
% tol     = 0.02;     % 2% band (for settling) - 修改这里，从0.05改为0.02
% t_delay = 0.002;    % ignore command-effective delay
% epsEnter = 0.03;    % enter ref neighborhood to start counting overshoot
% Tw_peak = 0.60;     % peak window length after entering neighborhood
% 
% % ---- Read from Te (struct with time format) ----
% t = Te.time(:);
% y = Te.signals.values;
% if size(y,2) > 1
%     y = y(:,1);  % 如果多列，取第一列
% end
% y = y(:);
% 
% [~, order] = sort(t); 
% t = t(order); 
% y = y(order);
% 
% % ---- start after delay ----
% tStart = t0 + t_delay;
% idxA = t >= tStart;
% tA = t(idxA);  
% yA = y(idxA);
% 
% % ---- find "enter neighborhood" time (avoid counting the falling edge) ----
% enterBand = epsEnter * abs(ref);
% kEnter = find(abs(yA - ref) <= enterBand, 1, 'first');
% if isempty(kEnter)
%     error('Never enters ref±epsEnter band after t0+t_delay. Increase epsEnter or check ref/t0.');
% end
% t_enter = tA(kEnter);
% 
% % ---- Overshoot only after entering neighborhood ----
% idxPeak = (t >= t_enter) & (t <= t_enter + Tw_peak);
% y_peak_window = max(y(idxPeak));
% OS_pct = max(0, (y_peak_window - ref)/abs(ref)*100);
% 
% % ---- Settling time (classic: stay within ±2% band afterwards) ----
% band = tol * abs(ref);  % 现在是 ±2%
% idxSet = t >= t_enter;
% tS = t(idxSet); 
% yS = y(idxSet);
% 
% inBand = abs(yS - ref) <= band;
% kLastOut = find(~inBand, 1, 'last');
% if isempty(kLastOut)
%     ST = 0;            % already always within band
% elseif kLastOut == numel(tS)
%     ST = NaN;          % never settles by end of sim
% else
%     ST = tS(kLastOut+1) - t0;  % relative to step time t0
% end
% 
% %% ============================================================
% %  C) THD from ia struct (window t1-t2)
% %% ============================================================
% t1 = 3.5;   % FFT window start
% t2 = 3.8;   % FFT window end
% 
% rpm = 1200;
% pn  = 4;                 % pole pairs
% f0  = pn * (rpm/60);     % electrical fundamental
% 
% useHann  = false;        % powergui often like rectangular unless specified
% removeDC = true;
% 
% % ---- Extract from struct with time ----
% tt = ia.time(:);
% xx = ia.signals.values;
% if size(xx,2) > 1
%     xx = xx(:,1);
% end
% xx = xx(:);
% 
% idx = (tt >= t1) & (tt <= t2);
% tw = tt(idx);
% xw = xx(idx);
% 
% if numel(xw) < 8
%     error('FFT window too short or data too sparse: N=%d', numel(xw));
% end
% 
% Ts = mean(diff(tw));
% fs = 1/Ts;
% 
% if removeDC
%     xw = xw - mean(xw);
% end
% 
% N = length(xw);
% if useHann
%     w = hann(N);
% else
%     w = ones(N,1);
% end
% 
% xwin = xw .* w;
% X = fft(xwin);
% 
% f = (0:N-1) * (fs/N);
% N2 = floor(N/2)+1;
% f1 = f(1:N2);
% X1 = X(1:N2);
% 
% df = fs/N;
% 
% % ---- magnitude scaling (keep your current style) ----
% if useHann
%     scale = sum(w)/2;
%     mag1 = abs(X1) / scale;
% else
%     mag1 = 2*abs(X1)/N;
%     mag1(1) = mag1(1)/2;
% end
% 
% % ---- THD (2..H) ----
% k1 = round(f0/df) + 1;
% k1 = max(2, min(k1, length(mag1)));   % guard
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
% 
% THD_pct = sqrt(Vh2)/max(V1,1e-12) * 100;
% 
% %% ============================================================
% %  D) Save by algorithm name (both struct + individual vars)
% %% ============================================================
% % ---- recommended structured storage ----
% if ~exist('Results','var') || ~isstruct(Results)
%     Results = struct();
% end
% Results.(tag).OS  = OS_pct;
% Results.(tag).ST  = ST;
% Results.(tag).THD = THD_pct;
% Results.(tag).Te  = Te;   % 保存完整的Te数据
% Results.(tag).ia  = ia;   % 保存完整的ia数据
% 
% % ---- variables like OS_PI, ST_PI, THD_PI ----
% assignin('base', "OS_"  + tag, OS_pct);
% assignin('base', "ST_"  + tag, ST);
% assignin('base', "THD_" + tag, THD_pct);
% 
% fprintf('\n====== Algorithm: %s (CA=%d) ======\n', tag, CA_val);
% fprintf('Overshoot (OS_%s)  = %.3f%%\n', tag, OS_pct);
% fprintf('Settling Time (ST_%s, ±2%%) = %.6f s\n', tag, ST);  % 添加说明
% fprintf('THD (THD_%s)       = %.3f%%\n', tag, THD_pct);
% fprintf('=====================================\n\n');
