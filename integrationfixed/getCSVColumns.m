function [col1, col2, col3,col4] = getCSVColumns(filename)
    % Read the CSV file, skip the header row
    data = readmatrix(filename, 'NumHeaderLines', 1);

    % Extract columns
    col1 = data(:, 1);  % First column
    col2 = data(:, 2);  % Second column
    col3 = data(:, 3);  % Third column
    col4 = data(:, 4);  % Fourth Column

    % Add more columns as needed depending on your CSV structure
end
