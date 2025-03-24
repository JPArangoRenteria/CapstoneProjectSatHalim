% Calculate Bit Rate
function bitRate = calculateBitRate(bandwidth,modType,modOrder,modIndex)

    % Check for modulation scheme
    if strcmp(modType,'QAM') || strcmp(modType,'PSK')
        bitRate = bandwidth * log2(modOrder);
    end
    if strcmp(modType,'FSK')
        bitRate = bandwidth / (2 * (1+modIndex));
    end
    
end