function plot_radar_wrapper()
    % 包装函数 - 不修改任何现有代码
    % 这个文件单独保存，不修改app1.mlapp
    
    fprintf('=== 雷达图包装函数 ===\n');
    
    % 1. 检查数据是否存在
    if ~evalin('base', 'exist(''CA1'', ''var'')')
        error('请在workspace中运行仿真生成CA1变量');
    end
    if ~evalin('base', 'exist(''Te'', ''var'')')
        error('请在workspace中运行仿真生成Te变量');
    end
    if ~evalin('base', 'exist(''ia'', ''var'')')
        error('请在workspace中运行仿真生成ia变量');
    end
    
    % 2. 获取数据
    CA1 = evalin('base', 'CA1');
    Te = evalin('base', 'Te');
    ia = evalin('base', 'ia');
    
    fprintf('数据获取成功\n');
    
    % 3. 调用原有函数
    out = calc_metrics_one_run(CA1, Te, ia);
    draw_radar_from_workspace();
    
    fprintf('完成！算法: %s\n', out.tag);
end