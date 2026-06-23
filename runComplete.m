function runComplete(CA_values)
    %% 完整的测试流程
    %% 用法: runComplete([0, 1, 2])  % 测试多个 CA 值
    
    if nargin < 1
        CA_values = [0, 1, 2];  % 默认测试 PI, DPC, MPC
    end
    
    fprintf('========================================\n');
    fprintf('PMSM 控制算法对比测试\n');
    fprintf('========================================\n\n');
    
    for i = 1:length(CA_values)
        CA_val = CA_values(i);
        
        % 清除旧输出
        evalin('base', 'clear Te ia CA1 TmTe wmref data_out tout');
        
        % 设置参数
        assignin('base', 'CA', CA_val);
        assignin('base', 'F', 0);
        assignin('base', 'J', 0.002);
        assignin('base', 'Ld', 0.0025);
        assignin('base', 'Lq', 0.0025);
        assignin('base', 'Ls', 0.005);
        assignin('base', 'Rs', 0.34);
        assignin('base', 'Tprofile', 0);
        assignin('base', 'Vdc', 200);
        assignin('base', 'Wmprofile', 0);
        assignin('base', 'fsw', 1e4);
        assignin('base', 'phi', 0.022);
        assignin('base', 'pn', 4);
        
        fprintf('\n===== 测试 CA = %d =====\n', CA_val);
        
        % 运行仿真
        tic;
        evalin('base', 'sim(''PMSMcontrolbenchmark'');');
        elapsed = toc;
        
        % 检查结果
        if evalin('base', "exist('Te', 'var')") && evalin('base', "exist('ia', 'var')")
            Te_len = evalin('base', 'length(Te)');
            ia_len = evalin('base', 'length(ia)');
            CA1_val = evalin('base', 'CA1');
            fprintf('✓ 仿真完成 (            fprintf('  Te: %d 点, ia: %d 点, CA1 = %d\n', Te_len, ia_len, CA1_val);
            
            % 计算指标（如果函数存在）
            if exist('calc_metrics_one_run', 'file')
                Te = evalin('base', 'Te');
                ia = evalin('base', 'ia');
                calc_metrics_one_run(CA_val, Te, ia);
                fprintf('  ✓ 指标已计算\n');
            end
        else
            fprintf('✗ 仿真失败，数据未导出\n');
        end
    end
    
    % 生成雷达图
    fprintf('\n===== 生成雷达图 =====\n');
    if exist('draw_radar_from_workspace', 'file')
        try
            draw_radar_from_workspace();
            fprintf('✓ 雷达图已生成\n');
        catch ME
            fprintf('✗ 雷达图生成失败: %s\n', ME.message);
        end
    else
        fprintf('⚠️ 未找到 draw_radar_from_workspace 函数\n');
    end
    
    fprintf('\n========================================\n');
    fprintf('测试完成！\n');
    fprintf('========================================\n');
end
