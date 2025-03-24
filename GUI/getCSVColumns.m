function [col1, col2, col3,col4] = getCSVColumns(filename)
    % Read the CSV file, skip the header row
    data = readtable(filename, 'NumHeaderLines', 1);

    % Extract columns
    col1 = table2array(data(:, 1));  % First column
    col2 = table2array(data(:, 2));  % Second column
    col3 = table2array(data(:, 3));  % Third column
    col4 = table2array(data(:, 4));  % Fourth Column

    % Add more columns as needed depending on your CSV structure
end
