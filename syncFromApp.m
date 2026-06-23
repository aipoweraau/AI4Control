function syncFromApp()
    %% 从 App 同步变量到 base workspace
    fprintf('正在同步变量...\n');
    
        varList = {'CA1', 'Te', 'ia', 'wmref', 'TmTe', 'data_out'};
    
    foundCount = 0;
    for i = 1:length(varList)
        varName = varList{i};
        if evalin('base', sprintf("exist('%s', 'var')", varName))
            val = evalin('base', varName);
            assignin('base', varName, val);
            fprintf('  ✓ %s: %s\n', varName, mat2str(size(val)));
            foundCount = foundCount + 1;
        else
            fprintf('  ✗ %s: 不存在\n', varName);
        end
    end
    
    if foundCount == length(varList)
        fprintf('\n✓ 所有变量已同步！\n');
    else
        fprintf('\n⚠️ 部分变量未找到\n');
    end
end
