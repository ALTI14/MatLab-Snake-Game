% Alper Şenol
function mysnake2()
% Game parameters

gridSize = 30; % Size of the world
initialSpeed = 0.25; % How fast the game updates

startX = round(gridSize/2); % Starting coordinates for the snake,
startY = round(gridSize/2); % is rounded for cases where gridSize is odd.

snake.segments = [
    startX, startY; %  Segment 1: head, spawns in the center
    startX, startY-1; % startY-1 and startY-2 is used 
    startX, startY-2; % to make the snake spawn vertically
    ];
snake.direction = 'up'; % to make the snake head upwards.
snake.running = true; % flag to control game loop, when false game ends
snake.score = 0;

uiwait(msgbox({ ... % uiwait(...) stops MATLAB execution until dialog is closed
    'W A S D to move the snake', ...
    'Esc to quit the game',...
    'Eat the block in RED to grow in size'}, ...
    'Welcome to MATLAB Snake','modal')) % modal blocks all other MATLAB windows

% Figure window creation

snake.fig = figure( ... % ellipsis to express line continuation (...)
    'Name', 'Snake Game by Alper', ... % Title of the window
    'NumberTitle', 'off', ... % Removes Figure 1: from the title
    'Color', 'k',... % Background colour, k for black
    'MenuBar', 'none',... % To remove menus (figure, format etc.)
    'KeyPressFcn', @key_pressed ... % Calls key_pressed 
              ...                      % whenever a key is pressed.
  );

snake.ax = axes(...
    'Parent', snake.fig, ... % To put the axes into the snake game window.
    'Units', 'normalized',... % To express position in relative units (0-1)
                         ... % this is to avoid problems when gridSize is changed.
    'Position', [0.05 0.05 0.9 0.9], ...% 1. (0.05) left margin 2. right 3. width
                          ...            % 4. height
    'XLim', [0.5 gridSize+0.5],...  % Sets horizontal coordinate 0.5 to gridSize
    'YLim', [0.5 gridSize+0.5],...
    'Color','k', ... % Black background for game space
    'XTick', [], ... % Removes tick marks and numbers from X axis
    'YTick', [], ... % Removes tick marks and numbers from Y axis
    'Box', 'on' ... % Draws a visible box around the game space
    );
%axis(snake.ax, 'equal'); % To ensure one unit in X equals one in Y
                         %(To create square cells) moves x axis as well


snake.food = [0,0]; % Will be used to store food coordinates.

cellSize = 1; % Width and height of one grid square
halfCell = cellSize/2; % 0.5 to shift from center to lower left

segSize = size(snake.segments,1); % How many blocks the snake has
snake.hSegments = [];

for i = 1:segSize
    % Centre of segment k
    cx = snake.segments(i,1); % (k,1) for x coord (center)
    cy = snake.segments(i,2); % (k,2) for y coord (center)
    % This method is used to draw a square that perfectly fills a single
    % grid cell each corresponding to snakes segments
    snake.hSegments(i) = rectangle( ...
        'Parent', snake.ax, ... % To draw inside game axes
        'Position', [cx-halfCell, cy-halfCell, cellSize, cellSize], ...
        ... % 1. x lower left 2. y lower left 3. width (horizontal) 4. height
        'FaceColor', 'g', ... % Fill with green inside
        'EdgeColor', 'k'); % Black outline to separate segments
end

fx = randi(gridSize-1); % random coords for food coordinates
fy = randi(gridSize-1);
snake.food = [fx fy]; % Store the coordinate inside snake.food

snake.hfood = rectangle( ...
    'Parent', snake.ax, ... % To draw inside game axes
    'Position', [fx-halfCell, fy-halfCell, cellSize, cellSize], ...
        ... % 1. x lower left 2. y lower left 3. width (horizontal) 4. height
    'FaceColor','r', ... % Fill with red inside
    'EdgeColor','r'); % Red outline

snake.hScore = text(0.5, gridSize+1.2, ... % in-game score label
    sprintf('Score: %d',snake.score), ...
    'Parent',snake.ax,'Color','w','FontWeight','bold', ...
    'HorizontalAlignment','left','VerticalAlignment','bottom');

snake.timer = timer( ...
    'ExecutionMode', 'fixedRate',... % To call at steady intervals
    'Period', initialSpeed, ... % Seconds between frames
    'TimerFcn', @gameTick); % main loop function

guidata(snake.fig, snake); % attaches snake struct to snake.fig
                           % to reach variables within snake struct
start(snake.timer);


function key_pressed(src, event)
% because it is set  'KeyPressFcn',@key_pressed  on the figure,
% src == snake.fig  (the main window)
% event.Key is string like 'uparrow','a','escape
snake = guidata(src);

% src is the figure, so this pulls the
% current 'snake' struct out of the figure's
% app-data where we stored it earlier.

switch event.Key
    case 'w'
        if ~strcmp(snake.direction,'down') % only if current dir is NOT 'down'
            snake.direction = 'up';
        end
    case 's'
        if ~strcmp(snake.direction,'up')
            snake.direction = 'down';
        end
    case 'a'
        if ~strcmp(snake.direction,'right') % corrected opposite check
            snake.direction = 'left';
        end
    case 'd'
        if ~strcmp(snake.direction,'left')
            snake.direction = 'right';
        end

    case 'escape'
        stop(snake.timer); delete(snake.timer); % stop timer
        close(src);
        return
end
guidata(src, snake); % the new snake.direction value
end


function gameTick(~,~)
%   • Moves the head one cell in the current direction
%   • Wraps around edges
%   • Checks if head is on the food to grow & relocate food
%   • Redraws all rectangles
snake = guidata(snake.fig); 
% use snake.fig directly (timer callbacks have no gcbf)

head = snake.segments(1,:); % [x y] of current head

delta = dir2vec(snake.direction); % 'up' → [0 1], etc.

newHd = head + delta; % one cell step

newHd = mod(newHd-1, gridSize) + 1; % wrap using known gridSize


if any(ismember(newHd, snake.segments, 'rows')) % head hits body?
    stop(snake.timer); delete(snake.timer); % stop and delete timer
    msgbox(sprintf('Game over!\nFinal score: %d',snake.score), ...
           'Game Over','modal');
    pause(3)
    close(snake.fig)
    return
end


snake.segments = [newHd; snake.segments];
ate = isequal(newHd, snake.food); % to check if head hit the food

if ~ate
    snake.segments(end,:) = [];
else
    snake.score = snake.score + 1;
    set(snake.hScore,'String',sprintf('Score: %d',snake.score)); % update score

    % food eaten new random cell is picked
    snake.food = [randi(gridSize-1) randi(gridSize-1)];

    set(snake.hfood,'Position', [snake.food-0.5 1 1]); % snake.hfood graphics handle
    % snake.food is the centre coordinate [fx fy] of the new food cell.
    % Subtract 0.5 from both elements to convert that centre into the lower-left
    % corner of the 1 × 1 square.
end

segN = size(snake.segments,1); % new snake length
if segN > numel(snake.hSegments) % grew this tick?
    snake.hSegments(segN) = rectangle('Parent',snake.ax, ...
        'Position',[0 0 1 1], ...
        'FaceColor','g', ...
        'EdgeColor','k'); % new tail block
end

% Move every rectangle to its matching segment
for k = 1:segN
    set(snake.hSegments(k), ...
        'Position',[snake.segments(k,:)-0.5  1 1]); % [xLowerLeft yLL w h]
end

guidata(snake.fig,snake);
end

function v = dir2vec(dirStr)
% convert direction string → [dx dy] step
switch dirStr
    case 'up',    v = [ 0  1];
    case 'down',  v = [ 0 -1];
    case 'left',  v = [-1  0];
    case 'right', v = [ 1  0];
end
end


end


