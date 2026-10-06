function hFig = draw_radar_from_workspace()
algorithms = {'PI','MPC','DPC'};

score_WQ = @(thd) max(0, min(1, (10 - thd) / (10 - 2)));
score_OR = @(os)  max(0, min(1, (15 - os) / (15 - 5)));
score_SS = @(st)  max(0, min(1, (10 - st * 1000) / (10 - 2)));



% comp_speed = struct('PI',1.0,'MPC',0.4,'DPC',0.7);
% robustness = struct('PI',1.0,'MPC',0.5,'DPC',0.85);


comp_speed = struct('PI',1.0,'MPC',0.0,'DPC',(50 - 17) / (50 - 4));
robustness = struct('PI',1.0,'MPC',2/3,'DPC',2/3);


available = {};
for i=1:numel(algorithms)
    a=algorithms{i};
    if evalin('base',sprintf("exist('OS_%s','var')&&exist('ST_%s','var')&&exist('THD_%s','var')",a,a,a))
        available{end+1}=a; %#ok<AGROW>
    end
end
if isempty(available)
    error('No OS_/ST_/THD_ variables found in base workspace.');
end

n_available = numel(available);
scores = zeros(5,n_available);

for i=1:n_available
    a=available{i};
    os = evalin('base',sprintf('OS_%s',a));
    st = evalin('base',sprintf('ST_%s',a));
    thd= evalin('base',sprintf('THD_%s',a));
    scores(1,i)=score_SS(st);
    scores(2,i)=score_OR(os);
    scores(3,i)=score_WQ(thd);
    scores(4,i)=robustness.(a);
    scores(5,i)=comp_speed.(a);
end

hFig = figure('Name','Radar Plot','Color','w','Position',[100 100 900 800]);
categories = {'Settling Speed','Overshoot Reduction','Waveform Quality','Robustness','Computation Speed'};

color_map = struct('PI',[0.2 0.4 0.8],'MPC',[1.0 0.4 0.2],'DPC',[0.8 0.2 0.8]);
colors = zeros(n_available,3);
for i=1:n_available, colors(i,:)=color_map.(available{i}); end

theta = linspace(0,2*pi,6); theta=theta(1:end-1); theta=theta+pi/2;

hold on;
for level=[0.2 0.4 0.6 0.8 1.0]
    xg=level*cos(theta); yg=level*sin(theta);
    plot([xg xg(1)],[yg yg(1)],'Color',[0.8 0.8 0.8],'LineWidth',0.5);
end

%%
% ===== Radial tick labels (show 0.2/0.4/.../1.0) =====
tick_levels = [0.2 0.4 0.6 0.8 1.0];

% 
ang = theta(1) - deg2rad(12);
for lv = tick_levels
    xt = (lv+0.02) * cos(ang);
    yt = (lv+0.02) * sin(ang);
    text(xt, yt, sprintf('%.1f', lv), ...
        'FontSize', 10, 'Color', [0.35 0.35 0.35], ...
        'HorizontalAlignment','center','VerticalAlignment','middle');
end
text(0, 0, '0', 'FontSize', 10, 'Color', [0.35 0.35 0.35], ...
    'HorizontalAlignment','center','VerticalAlignment','middle');

%%

for k=1:5
    plot([0 cos(theta(k))],[0 sin(theta(k))],'Color',[0.5 0.5 0.5],'LineWidth',0.5);
end

legend_handles = gobjects(1,n_available);
for i=1:n_available
    s=scores(:,i);
    x=s'.*cos(theta); y=s'.*sin(theta);
    xc=[x x(1)]; yc=[y y(1)];
    legend_handles(i)=fill(xc,yc,colors(i,:),'FaceAlpha',0.25,'EdgeColor',colors(i,:),'LineWidth',2.5);
    plot(x,y,'o','Color',colors(i,:),'MarkerFaceColor',colors(i,:),'MarkerSize',10);
end

label_offset=1.2;
for k=1:5
    xl=label_offset*cos(theta(k)); yl=label_offset*sin(theta(k));
    ha = 'center'; if xl>0.1, ha='left'; elseif xl<-0.1, ha='right'; end
    va = 'middle'; if yl>0.1, va='bottom'; elseif yl<-0.1, va='top'; end
    text(xl,yl,categories{k},'HorizontalAlignment',ha,'VerticalAlignment',va,'FontSize',12,'FontWeight','bold');
end

axis equal; axis off;
xlim([-1.4 1.4]); ylim([-1.6 1.4]);
title('Control Algorithm Performance Comparison','FontSize',16,'FontWeight','bold');
legend(legend_handles,available,'Location','southoutside','Orientation','horizontal','FontSize',12,'Box','off');
hold off;
end
