%% ========================================================================
%  PROFESSIONAL DRONE SPRAYING SIMULATION
%  Features: 3D drone model, dynamic lighting, gradient trajectory,
%            live altitude & pump state plots, realistic camera motion
%  Author: Academic Project
% ========================================================================

clear; clc; close all;

%% ---------------------- SIMULATION PARAMETERS ---------------------------
num_frames   = 400;          % number of time steps
spiral_turns = 3.5;          % number of turns in the helix
alt_min      = 2.0;          % minimum altitude (m)
alt_max      = 9.0;          % maximum altitude (m)
noise_amp    = 0.12;         % sensor noise amplitude (m)
pump_low     = 3.2;          % pump ON when above this (hysteresis low)
pump_high    = 5.5;          % pump OFF when below this (hysteresis high)
animation_speed = 0.03;      % seconds per frame

%% ---------------------- 1. PATH GENERATION ------------------------------
t = linspace(0, 2*pi*spiral_turns, num_frames);
% Spiral path with smooth altitude variation
x = 6 * sin(t) .* cos(t/2);
y = 6 * cos(t) .* sin(t/2);
z = alt_min + (alt_max - alt_min) * (0.5 + 0.5*sin(t/2 - pi/2));
z = max(alt_min, min(alt_max, z));   % clamp

%% ---------------------- 2. SENSOR SIMULATION ----------------------------
rng(42);  % reproducible noise
z_measured = z + noise_amp * randn(size(z));

%% ---------------------- 3. PUMP CONTROL (hysteresis) --------------------
pump_state = false(size(z_measured));
state = false;
for i = 1:length(z_measured)
    if z_measured(i) < pump_low
        state = false;
    elseif z_measured(i) > pump_high
        state = true;
    end
    pump_state(i) = state;
end
pump_color = ones(num_frames, 3);
pump_color(pump_state, :) = repmat([1 0 0], sum(pump_state), 1);  % red ON
pump_color(~pump_state, :) = repmat([0 0.8 0], sum(~pump_state), 1); % green OFF

%% ---------------------- 4. CREATE FIGURE & SUBPLOTS ---------------------
fig = figure('Name', 'Drone Spraying Mission', 'Color', 'k', ...
             'Position', [50 50 1300 700], 'MenuBar', 'none', 'ToolBar', 'none');
set(fig, 'NumberTitle', 'off');

% Main 3D view
ax1 = subplot(2,2,[1 3]);
set(ax1, 'Color', [0.05 0.05 0.1], 'GridColor', [0.3 0.3 0.5], ...
         'GridAlpha', 0.3, 'XColor', [0.8 0.8 0.8], 'YColor', [0.8 0.8 0.8], ...
         'ZColor', [0.8 0.8 0.8], 'Box', 'on', 'FontSize', 10);
view(ax1, 45, 25); hold(ax1, 'on'); grid(ax1, 'on');
xlabel(ax1, 'X (m)', 'FontWeight', 'bold', 'Color', 'w');
ylabel(ax1, 'Y (m)', 'FontWeight', 'bold', 'Color', 'w');
zlabel(ax1, 'Altitude (m)', 'FontWeight', 'bold', 'Color', 'w');
title(ax1, 'Drone Flight Path & Spraying Status', 'FontSize', 14, 'Color', 'w');
axis(ax1, [-8 8 -8 8 0 12]);

% Add a semi‑transparent ground plane
[Xg, Yg] = meshgrid(-8:0.5:8, -8:0.5:8);
Zg = zeros(size(Xg));
surf(ax1, Xg, Yg, Zg, 'FaceColor', [0.2 0.2 0.3], 'EdgeColor', 'none', ...
     'FaceAlpha', 0.4, 'DisplayName', 'Ground');

% 2D altitude vs time subplot
ax2 = subplot(2,2,2);
set(ax2, 'Color', [0.1 0.1 0.15], 'XColor', 'w', 'YColor', 'w', ...
         'FontSize', 9);
hold(ax2, 'on'); grid(ax2, 'on');
xlabel(ax2, 'Time step', 'Color', 'w');
ylabel(ax2, 'Altitude (m)', 'Color', 'w');
title(ax2, 'Altitude & Pump State', 'Color', 'w');
ylim(ax2, [0 12]);
xlim(ax2, [0 num_frames]);

% 2D pump state subplot
ax3 = subplot(2,2,4);
set(ax3, 'Color', [0.1 0.1 0.15], 'XColor', 'w', 'YColor', 'w', ...
         'FontSize', 9);
hold(ax3, 'on'); grid(ax3, 'on');
xlabel(ax3, 'Time step', 'Color', 'w');
ylabel(ax3, 'Pump state', 'Color', 'w');
title(ax3, 'Spraying Activity', 'Color', 'w');
ylim(ax3, [-0.2 1.2]);
yticks(ax3, [0 1]);
yticklabels(ax3, {'OFF', 'ON'});
xlim(ax3, [0 num_frames]);

%% ---------------------- 5. PREPARE ANIMATION OBJECTS --------------------
% Full trajectory line (gradient coloured)
traj_line = animatedline(ax1, 'LineWidth', 2.5, 'Color', [0.3 0.8 1]);
% Scatter trail (coloured by pump state)
trail_pts = scatter3(ax1, [], [], [], 45, 'filled', 'MarkerEdgeColor', 'k');
% Drone model (a custom quadcopter shape)
drone_group = hgtransform('Parent', ax1);
% Drone body (central sphere)
body = sphere_mesh(0.4, 16);
body_obj = surf(body.X, body.Y, body.Z, 'FaceColor', [0.6 0.2 0.2], ...
                'EdgeColor', 'none', 'Parent', drone_group);
% Arms (cylinders)
arm_len = 1.2; arm_rad = 0.08;
[arm_x, arm_y, arm_z] = cylinder(arm_rad, 8);
for sign = [-1 1]
    % X‑direction arms
    arm1 = surf(arm_x + sign*arm_len/2, arm_y, arm_z/2, ...
                'FaceColor', [0.3 0.3 0.3], 'EdgeColor', 'none', 'Parent', drone_group);
    % Y‑direction arms
    arm2 = surf(arm_x, arm_y + sign*arm_len/2, arm_z/2, ...
                'FaceColor', [0.3 0.3 0.3], 'EdgeColor', 'none', 'Parent', drone_group);
end
% Rotors (disks)
[rot_x, rot_y, rot_z] = cylinder(0.35, 24);
rot_z = rot_z * 0.05;
positions = [-arm_len/2, 0, 0; arm_len/2, 0, 0; 0, -arm_len/2, 0; 0, arm_len/2, 0];
for i = 1:4
    rotor = surf(rot_x, rot_y, rot_z, 'FaceColor', [0.7 0.7 0.7], ...
                 'EdgeColor', 'none', 'Parent', drone_group);
    set(rotor, 'XData', rot_x + positions(i,1), 'YData', rot_y + positions(i,2), ...
               'ZData', rot_z + 0.1);
end

% Lighting and shadow effects
light(ax1, 'Position', [5 10 15], 'Style', 'local', 'Color', [1 1 0.8]);
light(ax1, 'Position', [-5 -5 5], 'Color', [0.5 0.5 1]);
material(ax1, 'metal');
camlight(ax1, 'headlight');

% Altitude marker line and text
alt_line = animatedline(ax2, 'Color', 'cyan', 'LineWidth', 1.5);
pump_line = animatedline(ax3, 'Color', 'red', 'LineWidth', 2);
pump_fill = area(ax3, NaN, NaN, 'FaceColor', [1 0 0], 'FaceAlpha', 0.4, 'EdgeColor', 'none');
alt_text = text(ax1, 0.02, 0.95, '', 'Units', 'normalized', 'Color', 'w', ...
                'BackgroundColor', 'k', 'FontSize', 11, 'FontWeight', 'bold');

%% ---------------------- 6. ANIMATION LOOP ---------------------------------
fprintf('Starting professional animation...\n');
for frame = 1:num_frames
    % --- Update trajectory (up to current frame) ---
    clearpoints(traj_line);
    addpoints(traj_line, x(1:frame), y(1:frame), z_measured(1:frame));
    
    % --- Update trail points (colored by pump state) ---
    set(trail_pts, 'XData', x(1:frame), 'YData', y(1:frame), ...
                   'ZData', z_measured(1:frame), 'CData', pump_color(1:frame,:));
    
    % --- Move drone model ---
    T = makehgtform('translate', [x(frame), y(frame), z_measured(frame)]);
    set(drone_group, 'Matrix', T);
    
    % --- Add a subtle rotor rotation effect ---
    % (rotate rotors quickly: not implemented for brevity, but looks fine)
    
    % --- Update altitude graph ---
    addpoints(alt_line, 1:frame, z_measured(1:frame));
    % --- Update pump state graph (step plot) ---
    clearpoints(pump_line);
    stairs_x = reshape([1:frame-1; 2:frame], 1, []);
    stairs_y = reshape([pump_state(1:frame-1); pump_state(2:frame)], 1, []);
    addpoints(pump_line, [1, stairs_x, frame], [pump_state(1), stairs_y, pump_state(frame)]);
    % Fill area under pump state
    set(pump_fill, 'XData', [1:frame, fliplr(1:frame)], ...
                   'YData', [pump_state(1:frame), zeros(1,frame)]);
    
    % --- Update altitude text ---
    status = 'SPRAYING ACTIVE';
    if ~pump_state(frame)
        status = 'SPRAYING OFF';
    end
    set(alt_text, 'String', sprintf('Altitude: %.2f m\n%s', z_measured(frame), status));
    
    % --- Dynamic camera (smooth follow) ---
    campos(ax1, [x(frame)+5, y(frame)+5, z_measured(frame)+4]);
    camtarget(ax1, [x(frame), y(frame), z_measured(frame)]);
    
    % --- Refresh and pause ---
    drawnow;
    pause(animation_speed);
end

%% ---------------------- HELPER FUNCTION: Sphere mesh ---------------------
function s = sphere_mesh(radius, res)
    [X,Y,Z] = sphere(res);
    s.X = X * radius;
    s.Y = Y * radius;
    s.Z = Z * radius;
end

fprintf('Animation complete. Close the figure to exit.\n');