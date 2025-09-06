function electrode_clusters = find_electrode_clusters(difference_waves, output_dir, cluster_size, ern_time_window, pe_time_window)
% find_electrode_clusters - identify ERN & Pe electrode clusters using cluster optimization
%
% this function identifies optimal electrode clusters for ERN and Pe based on:
% - cluster optimization approach (finds best cluster of size N, not peak + neighbors)
% - user-defined search regions with midline constraints
% - spatial adjacency constraints to ensure compact clusters
% - configurable time windows and cluster sizes
%
% inputs:
%   difference_waves - struct from compute_difference_waves containing difference waves
%   output_dir - path to save results
%   cluster_size - number of electrodes in cluster (1-5)
%   ern_time_window - [start, end] in ms for ERN analysis (e.g., [0, 100])
%   pe_time_window - [start, end] in ms for Pe analysis (e.g., [200, 500])
%
% outputs:
%   electrode_clusters - struct containing ERN & Pe cluster information
%
% author: Marlene Buch I 2025

fprintf('identifying electrode clusters using cluster optimization approach...\n');
fprintf('cluster size: %d electrodes\n', cluster_size);
fprintf('ERN time window: %d-%d ms\n', ern_time_window(1), ern_time_window(2));
fprintf('Pe time window: %d-%d ms\n', pe_time_window(1), pe_time_window(2));

% check if difference waves exist
if isempty(fieldnames(difference_waves)) || ~isfield(difference_waves, 'times')
    error('no difference waves provided - run compute_difference_waves first');
end

%% step 1: average all visible condition difference waves for cluster selection

fprintf('\nstep 1: averaging visible condition difference waves for cluster selection\n');

% identify available visible condition difference waves (match actual field names from batch script)
visible_waves = {};
visible_fields = {};

if isfield(difference_waves, 'soc_vis_FE')
    visible_waves{end+1} = difference_waves.soc_vis_FE;
    visible_fields{end+1} = 'soc_vis_FE';
end

if isfield(difference_waves, 'soc_vis_NFE')
    visible_waves{end+1} = difference_waves.soc_vis_NFE;
    visible_fields{end+1} = 'soc_vis_NFE';
end

if isfield(difference_waves, 'nonsoc_vis_FE')
    visible_waves{end+1} = difference_waves.nonsoc_vis_FE;
    visible_fields{end+1} = 'nonsoc_vis_FE';
end

if isfield(difference_waves, 'nonsoc_vis_NFE')
    visible_waves{end+1} = difference_waves.nonsoc_vis_NFE;
    visible_fields{end+1} = 'nonsoc_vis_NFE';
end

if isempty(visible_waves)
    error('no visible condition difference waves found for cluster selection');
end

fprintf('found %d visible condition difference waves: %s\n', length(visible_waves), strjoin(visible_fields, ', '));

% average visible waves across conditions & subjects
combined_visible_wave = zeros(size(visible_waves{1}, 1), size(visible_waves{1}, 2)); % 2D: channels x timepoints
for i = 1:length(visible_waves)
    % average across subjects (dimension 3) first, then add to combined wave
    wave_averaged = mean(visible_waves{i}, 3);
    combined_visible_wave = combined_visible_wave + wave_averaged;
end
combined_visible_wave = combined_visible_wave / length(visible_waves);

fprintf('combined visible difference wave created for cluster selection\n');

%% step 2: define electrode search regions & adjacency

fprintf('\nstep 2: defining electrode search regions & spatial adjacency\n');

% define search regions based on electrode layout
ern_search_region = [10, 43, 38, 6, 5, 37, 39, 4, 2, 1, 34, 36, 3, 33, 35, 17];
pe_search_region = [1, 33, 3, 35, 17, 20, 18, 49, 51, 22, 19, 50, 53, 23, 54, 24, 55];

% define midline electrodes (must include in clusters based on size)
midline_electrodes = [38, 5, 37, 2, 1, 34, 33, 17, 18, 49, 19, 50, 23];

% define adjacency matrix based on electrode layout
adjacency = containers.Map('KeyType', 'int32', 'ValueType', 'any');

% ERN search region adjacencies
adjacency(10) = [38, 43];
adjacency(43) = [10, 38]; 
adjacency(38) = [10, 43, 5, 37];
adjacency(6) = [5, 4];
adjacency(5) = [38, 6, 37, 2];
adjacency(37) = [38, 39, 5];
adjacency(39) = [36, 37, 34];
adjacency(4) = [6, 2, 3];
adjacency(2) = [5, 1, 4];
adjacency(34) = [37, 36, 1];
adjacency(36) = [39, 34, 35];

% Pe search region adjacencies  
adjacency(20) = [3, 22, 18];
adjacency(18) = [17, 20, 19];
adjacency(49) = [17, 51, 50];
adjacency(51) = [35, 49, 53];
adjacency(22) = [20, 19, 24];
adjacency(19) = [18, 50, 23, 22];
adjacency(50) = [49, 19, 23, 53];
adjacency(53) = [51, 50, 55];
adjacency(23) = [19, 50, 54];
adjacency(54) = [23];
adjacency(24) = [22];
adjacency(55) = [53];

% overlap electrodes (both regions)
adjacency(1) = [2, 34, 33];
adjacency(33) = [1, 17];
adjacency(3) = [4, 20];
adjacency(35) = [36, 51]; 
adjacency(17) = [18, 49, 33];

fprintf('defined search regions: ERN (%d electrodes), Pe (%d electrodes)\n', ...
    length(ern_search_region), length(pe_search_region));

%% step 3: convert electrode labels to indices & define time windows

% find electrode indices in chanlocs
electrode_labels = {difference_waves.chanlocs.labels};

ern_indices = zeros(1, length(ern_search_region));
pe_indices = zeros(1, length(pe_search_region));

for i = 1:length(ern_search_region)
    idx = find(strcmp(electrode_labels, num2str(ern_search_region(i))));
    if isempty(idx)
        error('electrode %d not found in channel locations', ern_search_region(i));
    end
    ern_indices(i) = idx;
end

for i = 1:length(pe_search_region)
    idx = find(strcmp(electrode_labels, num2str(pe_search_region(i))));
    if isempty(idx)
        error('electrode %d not found in channel locations', pe_search_region(i));
    end
    pe_indices(i) = idx;
end

% define time windows (convert ms to sample indices)
times_ms = difference_waves.times;

ern_start_idx = find(times_ms >= ern_time_window(1), 1, 'first');
ern_end_idx = find(times_ms <= ern_time_window(2), 1, 'last');
pe_start_idx = find(times_ms >= pe_time_window(1), 1, 'first');
pe_end_idx = find(times_ms <= pe_time_window(2), 1, 'last');

fprintf('time windows - ERN: %d-%d ms (samples %d-%d), Pe: %d-%d ms (samples %d-%d)\n', ...
    ern_time_window(1), ern_time_window(2), ern_start_idx, ern_end_idx, ...
    pe_time_window(1), pe_time_window(2), pe_start_idx, pe_end_idx);

%% step 4: generate & evaluate electrode clusters

fprintf('\nstep 3: generating & evaluating electrode clusters\n');

% find optimal ERN cluster
[ern_cluster, ern_amplitude, ern_peak_amp, ern_peak_time, ern_peak_electrode] = find_optimal_cluster(combined_visible_wave, ...
    ern_search_region, ern_indices, ern_start_idx, ern_end_idx, ...
    cluster_size, midline_electrodes, adjacency, 'ERN', times_ms);

% find optimal Pe cluster  
[pe_cluster, pe_amplitude, pe_peak_amp, pe_peak_time, pe_peak_electrode] = find_optimal_cluster(combined_visible_wave, ...
    pe_search_region, pe_indices, pe_start_idx, pe_end_idx, ...
    cluster_size, midline_electrodes, adjacency, 'Pe', times_ms);

%% step 5: create output structure

electrode_clusters = struct();

% ERN cluster info
electrode_clusters.ERN.cluster_electrodes = ern_cluster;
electrode_clusters.ERN.cluster_electrodes_labels = arrayfun(@num2str, ern_cluster, 'UniformOutput', false);
electrode_clusters.ERN.cluster_amplitude = ern_amplitude;
electrode_clusters.ERN.peak_amplitude = ern_peak_amp;
electrode_clusters.ERN.peak_time_ms = ern_peak_time;
electrode_clusters.ERN.peak_electrode = ern_peak_electrode;
electrode_clusters.ERN.time_window_ms = ern_time_window;
electrode_clusters.ERN.cluster_size = cluster_size;

% Pe cluster info
electrode_clusters.Pe.cluster_electrodes = pe_cluster;
electrode_clusters.Pe.cluster_electrodes_labels = arrayfun(@num2str, pe_cluster, 'UniformOutput', false);
electrode_clusters.Pe.cluster_amplitude = pe_amplitude;
electrode_clusters.Pe.peak_amplitude = pe_peak_amp;
electrode_clusters.Pe.peak_time_ms = pe_peak_time;
electrode_clusters.Pe.peak_electrode = pe_peak_electrode;
electrode_clusters.Pe.time_window_ms = pe_time_window;
electrode_clusters.Pe.cluster_size = cluster_size;

% metadata
electrode_clusters.method = 'cluster optimization with spatial adjacency constraints';
electrode_clusters.date_computed = datestr(now);

%% step 6: save results

% save electrode clusters
clusters_file = fullfile(output_dir, 'electrode_clusters.mat');
save(clusters_file, 'electrode_clusters');
fprintf('\nsaved electrode clusters: %s\n', clusters_file);

% save summary text file
summary_file = fullfile(output_dir, 'electrode_clusters_summary.txt');
fid = fopen(summary_file, 'w');
fprintf(fid, '=== ELECTRODE CLUSTERS SUMMARY ===\n');
fprintf(fid, 'Date: %s\n', datestr(now));
fprintf(fid, 'Method: %s\n', electrode_clusters.method);
fprintf(fid, 'Cluster size: %d electrodes\n\n', cluster_size);

fprintf(fid, 'ERN CLUSTER:\n');
fprintf(fid, '  Electrodes: %s\n', strjoin(electrode_clusters.ERN.cluster_electrodes_labels, ', '));
fprintf(fid, '  Mean amplitude: %.3f µV\n', electrode_clusters.ERN.cluster_amplitude);
fprintf(fid, '  Peak amplitude: %.3f µV at electrode %d at %d ms\n', ...
    electrode_clusters.ERN.peak_amplitude, electrode_clusters.ERN.peak_electrode, electrode_clusters.ERN.peak_time_ms);
fprintf(fid, '  Time window: %d-%d ms\n\n', ern_time_window(1), ern_time_window(2));

fprintf(fid, 'Pe CLUSTER:\n');
fprintf(fid, '  Electrodes: %s\n', strjoin(electrode_clusters.Pe.cluster_electrodes_labels, ', '));
fprintf(fid, '  Mean amplitude: %.3f µV\n', electrode_clusters.Pe.cluster_amplitude);
fprintf(fid, '  Peak amplitude: %.3f µV at electrode %d at %d ms\n', ...
    electrode_clusters.Pe.peak_amplitude, electrode_clusters.Pe.peak_electrode, electrode_clusters.Pe.peak_time_ms);
fprintf(fid, '  Time window: %d-%d ms\n', pe_time_window(1), pe_time_window(2));
fclose(fid);

fprintf('saved summary text file: %s\n', summary_file);

%% summary
fprintf('\n=== ELECTRODE CLUSTERS IDENTIFICATION COMPLETE ===\n');
fprintf('ERN cluster: %d electrodes [%s] with %.3f µV mean (peak: %.3f µV at electrode %d, %d ms)\n', ...
    length(ern_cluster), strjoin(electrode_clusters.ERN.cluster_electrodes_labels, ', '), ern_amplitude, ...
    ern_peak_amp, ern_peak_electrode, ern_peak_time);
fprintf('Pe cluster: %d electrodes [%s] with %.3f µV mean (peak: %.3f µV at electrode %d, %d ms)\n', ...
    length(pe_cluster), strjoin(electrode_clusters.Pe.cluster_electrodes_labels, ', '), pe_amplitude, ...
    pe_peak_amp, pe_peak_electrode, pe_peak_time);
fprintf('clusters ready for amplitude extraction in all conditions\n');
fprintf('================================\n');

end

%% helper function: find optimal electrode cluster
function [best_cluster, best_amplitude, peak_amplitude, peak_time, peak_electrode] = find_optimal_cluster(data, search_region, region_indices, ...
    start_idx, end_idx, cluster_size, midline_electrodes, adjacency, component_name, times_ms)

fprintf('finding optimal %s cluster of size %d\n', component_name, cluster_size);

% generate all valid clusters
valid_clusters = generate_valid_clusters(search_region, cluster_size, midline_electrodes, adjacency);

if isempty(valid_clusters)
    error('no valid clusters found for %s with size %d', component_name, cluster_size);
end

fprintf('evaluating %d valid %s clusters\n', length(valid_clusters), component_name);

% evaluate each cluster
best_amplitude = -inf; % will be overwritten
best_cluster = [];
peak_amplitude = 0;
peak_time = 0;
peak_electrode = 0;

for i = 1:length(valid_clusters)
    cluster = valid_clusters{i};
    
    % convert electrode numbers to indices
    cluster_indices = zeros(1, length(cluster));
    for j = 1:length(cluster)
        electrode_num = cluster(j);
        region_pos = find(search_region == electrode_num);
        if ~isempty(region_pos)
            cluster_indices(j) = region_indices(region_pos);
        else
            error('electrode %d not found in search region', electrode_num);
        end
    end
    
    % extract data for this cluster in time window & compute mean amplitude
    cluster_data = data(cluster_indices, start_idx:end_idx);
    mean_amplitude = mean(cluster_data(:));
    
    % select best cluster based on component type
    if strcmp(component_name, 'ERN')
        % for ERN: most negative amplitude
        if mean_amplitude < best_amplitude || i == 1
            best_amplitude = mean_amplitude;
            best_cluster = cluster;
            
            % find peak (most negative) within this cluster
            [cluster_peak_amp, peak_idx] = min(cluster_data(:));
            [peak_electrode_idx, peak_time_idx] = ind2sub(size(cluster_data), peak_idx);
            peak_amplitude = cluster_peak_amp;
            peak_time = times_ms(start_idx + peak_time_idx - 1);
            peak_electrode = cluster(peak_electrode_idx);
        end
    else % Pe
        % for Pe: most positive amplitude
        if mean_amplitude > best_amplitude || i == 1
            best_amplitude = mean_amplitude;
            best_cluster = cluster;
            
            % find peak (most positive) within this cluster
            [cluster_peak_amp, peak_idx] = max(cluster_data(:));
            [peak_electrode_idx, peak_time_idx] = ind2sub(size(cluster_data), peak_idx);
            peak_amplitude = cluster_peak_amp;
            peak_time = times_ms(start_idx + peak_time_idx - 1);
            peak_electrode = cluster(peak_electrode_idx);
        end
    end
end

fprintf('optimal %s cluster found: [%s] with %.3f µV mean\n', component_name, ...
    strjoin(arrayfun(@num2str, best_cluster, 'UniformOutput', false), ', '), best_amplitude);
fprintf('  peak: %.3f µV at electrode %d at %d ms\n', peak_amplitude, peak_electrode, peak_time);

end

%% helper function: generate all valid clusters
function valid_clusters = generate_valid_clusters(search_region, cluster_size, midline_electrodes, adjacency)

% generate all possible combinations of cluster_size electrodes from search region
all_combinations = nchoosek(search_region, cluster_size);

valid_clusters = {};

for i = 1:size(all_combinations, 1)
    cluster = all_combinations(i, :);
    
    % check constraints
    if check_midline_constraint(cluster, cluster_size, midline_electrodes) && ...
       check_connectivity_constraint(cluster, adjacency) && ...
       check_compactness_constraint(cluster, adjacency)
        valid_clusters{end+1} = cluster;
    end
end

end

%% helper function: check midline electrode constraint
function valid = check_midline_constraint(cluster, cluster_size, midline_electrodes)

midline_count = sum(ismember(cluster, midline_electrodes));

if cluster_size <= 2
    valid = midline_count >= 1;
elseif cluster_size <= 4
    valid = midline_count >= 2;
else % cluster_size == 5
    valid = midline_count >= 3;
end

end

%% helper function: check connectivity constraint
function valid = check_connectivity_constraint(cluster, adjacency)

% all electrodes in cluster must form a connected graph
% use breadth-first search to check connectivity

if length(cluster) == 1
    valid = true;
    return;
end

% start from first electrode
visited = false(1, length(cluster));
queue = 1; % indices into cluster array
visited(1) = true;

while ~isempty(queue)
    current_idx = queue(1);
    queue(1) = [];
    
    current_electrode = cluster(current_idx);
    
    % get neighbors of current electrode that are also in cluster
    if adjacency.isKey(current_electrode)
        neighbors = adjacency(current_electrode);
        
        for neighbor = neighbors
            neighbor_idx = find(cluster == neighbor);
            if ~isempty(neighbor_idx) && ~visited(neighbor_idx)
                visited(neighbor_idx) = true;
                queue(end+1) = neighbor_idx;
            end
        end
    end
end

% all electrodes should be visited for connectivity
valid = all(visited);

end

%% helper function: check compactness constraint
function valid = check_compactness_constraint(cluster, adjacency)

% calculate maximum distance between any two electrodes in cluster
max_allowed_distance = get_max_allowed_distance(length(cluster));

max_distance = 0;

for i = 1:length(cluster)
    for j = i+1:length(cluster)
        distance = calculate_graph_distance(cluster(i), cluster(j), adjacency);
        if distance > max_distance
            max_distance = distance;
        end
    end
end

valid = max_distance <= max_allowed_distance;

end

%% helper function: get maximum allowed distance for compactness
function max_distance = get_max_allowed_distance(cluster_size)

if cluster_size <= 4
    max_distance = 2;
else % cluster_size == 5
    max_distance = 3;
end

end

%% helper function: calculate graph distance between two electrodes
function distance = calculate_graph_distance(electrode1, electrode2, adjacency)

if electrode1 == electrode2
    distance = 0;
    return;
end

% breadth-first search to find shortest path
visited = containers.Map('KeyType', 'int32', 'ValueType', 'logical');
queue = [electrode1];
distances = containers.Map('KeyType', 'int32', 'ValueType', 'int32');

visited(electrode1) = true;
distances(electrode1) = 0;

while ~isempty(queue)
    current = queue(1);
    queue(1) = [];
    
    if current == electrode2
        distance = distances(current);
        return;
    end
    
    % explore neighbors
    if adjacency.isKey(current)
        neighbors = adjacency(current);
        
        for neighbor = neighbors
            if ~visited.isKey(neighbor) || ~visited(neighbor)
                visited(neighbor) = true;
                distances(neighbor) = distances(current) + 1;
                queue(end+1) = neighbor;
            end
        end
    end
end

% if no path found, return large distance
distance = inf;

end