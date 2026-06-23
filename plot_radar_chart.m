function out = calc_metrics_one_run(CA, Te, ia)
% out: struct with fields tag, OS, ST, THD

CA_val = round(double(CA));
switch CA_val
    case 0, tag = "PI";
    case 1, tag = "MPC";
    case 2, tag = "DPC";
    otherwise, error('CA must be 0/1/2, current=%g', CA_val);
end

% ======= B) OS + ST from Te =======
t0=3.0; ref=1.0; tol=0.05; t_delay=0.002; epsEnter=0.03; Tw_peak=0.60;

t = Te.time(:);
y = squeeze(Te.signals.values);
if size(y,2)>1, y=y(:,1); end
y = y(:);

[~,idx]=sort(t); t=t(idx); y=y(idx);

tStart = t0 + t_delay;
tA = t(t>=tStart);
yA = y(t>=tStart);

enterBand = epsEnter*abs(ref);
kEnter = find(abs(yA-ref)<=enterBand,1,'first');
if isempty(kEnter), error('Never enters ref band'); end
t_enter = tA(kEnter);

idxPeak = (t>=t_enter) & (t<=t_enter+Tw_peak);
y_peak_window = max(y(idxPeak));
OS_pct = max(0,(y_peak_window-ref)/abs(ref)*100);

band = tol*abs(ref);
tS = t(t>=t_enter);
yS = y(t>=t_enter);
inBand = abs(yS-ref)<=band;
kLastOut = find(~inBand,1,'last');
if isempty(kLastOut)
    ST = 0;
elseif kLastOut==numel(tS)
    ST = NaN;
else
    ST = tS(kLastOut+1)-t0;
end

% ======= C) THD from ia =======
t1=3.5; t2=3.8;
rpm=1200; pn=4; f0=pn*(rpm/60);
useHann=false; removeDC=true;

tt = ia.time(:);
xx = squeeze(ia.signals.values);
if size(xx,2)>1, xx=xx(:,1); end
xx=xx(:);

idw = (tt>=t1)&(tt<=t2);
tw=tt(idw); xw=xx(idw);

if numel(xw)<8, error('FFT window too short'); end
Ts=mean(diff(tw)); fs=1/Ts;
if removeDC, xw=xw-mean(xw); end
N=length(xw);
w = useHann*hann(N) + (~useHann)*ones(N,1);
xwin=xw.*w;
X=fft(xwin);

f=(0:N-1)*(fs/N);
N2=floor(N/2)+1;
X1=X(1:N2);
df=fs/N;

if useHann
    scale=sum(w)/2;
    mag1=abs(X1)/scale;
else
    mag1=2*abs(X1)/N;
    mag1(1)=mag1(1)/2;
end

k1=round(f0/df)+1;
k1=max(2,min(k1,length(mag1)));
V1=mag1(k1);

H=40; Vh2=0;
for h=2:H
    kh=round(h*f0/df)+1;
    if kh<=length(mag1), Vh2=Vh2+mag1(kh)^2; end
end
THD_pct=sqrt(Vh2)/max(V1,1e-12)*100;

% ======= D) save like before =======
if evalin('base',"~exist('Results','var') || ~isstruct(Results)")
    evalin('base',"Results = struct();");
end
evalin('base', sprintf("Results.%s = struct();", tag));
evalin('base', sprintf("Results.%s.OS = %g;", tag, OS_pct));
evalin('base', sprintf("Results.%s.ST = %g;", tag, ST));
evalin('base', sprintf("Results.%s.THD = %g;", tag, THD_pct));

assignin('base',"OS_"+tag,OS_pct);
assignin('base',"ST_"+tag,ST);
assignin('base',"THD_"+tag,THD_pct);

out = struct('tag',tag,'OS',OS_pct,'ST',ST,'THD',THD_pct);
end
