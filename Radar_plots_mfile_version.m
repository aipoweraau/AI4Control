%% ============================================================
%  A) Identify algorithm by CA
%% ============================================================
% ===== Robust extraction for CA (struct with time) =====




% CA_val = round(double(CA));   % CA 是 1x1 double
% 
% 
% switch CA_val
%     case 0, tag = "PI";
%     case 1, tag = "MPC";
%     case 2, tag = "DPC";
%     otherwise
%         error('CA must be 0/1/2, current = %g', CA_val);
% end


% ---- Robust CA extraction: CA can be double OR struct ----
if isnumeric(CA)
    CA_val = round(double(CA));

elseif isstruct(CA) && isfield(CA,'signals') && isfield(CA.signals,'values')
    v = CA.signals.values;
    v = v(:);
    CA_val = round(double(v(end)));

else
    error('Unsupported CA type. class(CA) = %s', class(CA));
end

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




%% ===== 4. 绘制雷达图 =====
figure('Color', 'w', 'Position', [100, 100, 900, 800]);

% 指标名称
categories = {'Settling Speed', 'Overshoot Reduction', 'Waveform Quality', ...
              'Robustness', 'Computation Speed'};

% 颜色定义 (与示例图匹配) - 为每个算法固定颜色
color_map = struct();
color_map.PI  = [0.2, 0.4, 0.8];   % 蓝色
color_map.MPC = [1.0, 0.4, 0.2];   % 橙红色
color_map.DPC = [0.8, 0.2, 0.8];   % 紫红色

% 为可用算法选择对应的颜色
colors = zeros(n_available, 3);
for i = 1:n_available
    colors(i, :) = color_map.(algo_names_plot{i});
end

% 角度设置 (五边形)
theta = linspace(0, 2*pi, 6);
theta = theta(1:end-1);  % 移除重复点

% 调整起始角度，使第一个指标在顶部
theta = theta + pi/2;

% 绘制背景网格
hold on;
grid_levels = [0.2, 0.4, 0.6, 0.8, 1.0];
for level = grid_levels
    x_grid = level * cos(theta);
    y_grid = level * sin(theta);
    plot([x_grid, x_grid(1)], [y_grid, y_grid(1)], ...
         'Color', [0.8, 0.8, 0.8], 'LineWidth', 0.5);
end

% 绘制坐标轴线
for i = 1:5
    plot([0, cos(theta(i))], [0, sin(theta(i))], ...
         'Color', [0.5, 0.5, 0.5], 'LineWidth', 0.5);
end

% 绘制各算法的雷达图 (只绘制可用的)
for i = 1:n_available
    % 获取该算法的分数
    algo_scores = scores(:, i);
    
    % 转换为笛卡尔坐标
    x = algo_scores' .* cos(theta);
    y = algo_scores' .* sin(theta);
    
    % 闭合多边形
    x_closed = [x, x(1)];
    y_closed = [y, y(1)];
    
    % 填充区域
    fill(x_closed, y_closed, colors(i,:), ...
         'FaceAlpha', 0.25, 'EdgeColor', colors(i,:), ...
         'LineWidth', 2.5);
    
    % 绘制数据点
    plot(x, y, 'o', 'Color', colors(i,:), ...
         'MarkerFaceColor', colors(i,:), 'MarkerSize', 10);
end

% 添加指标标签
label_offset = 1.2;  % 标签距离中心的倍数
for i = 1:5
    x_label = label_offset * cos(theta(i));
    y_label = label_offset * sin(theta(i));
    
    % 根据位置调整文本对齐方式
    if abs(x_label) < 0.1
        ha = 'center';
    elseif x_label > 0
        ha = 'left';
    else
        ha = 'right';
    end
    
    if abs(y_label) < 0.1
        va = 'middle';
    elseif y_label > 0
        va = 'bottom';
    else
        va = 'top';
    end
    
    text(x_label, y_label, categories{i}, ...
         'HorizontalAlignment', ha, 'VerticalAlignment', va, ...
         'FontSize', 12, 'FontWeight', 'bold', 'Color', [0.2, 0.2, 0.4]);
end

% 设置坐标轴
axis equal;
axis off;
xlim([-1.4, 1.4]);
ylim([-1.6, 1.4]);

% 添加标题
title('Control Algorithm Performance Comparison', ...
      'FontSize', 16, 'FontWeight', 'bold', 'Color', [0.2, 0.2, 0.4]);

% 添加图例 (只显示可用的算法)
legend(algo_names_plot, 'Location', 'southoutside', 'Orientation', 'horizontal', ...
       'FontSize', 12, 'Box', 'off');

% 添加副标题说明
text(0, -1.55, 'Radar Chart', ...
     'HorizontalAlignment', 'center', 'FontSize', 11, ...
     'Color', [0.5, 0.5, 0.5]);

hold off;