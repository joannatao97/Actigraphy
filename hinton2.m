function h = hinton2(color, w)
%HINTON	Plot Hinton diagram for a weight matrix.
%
%	Description
%
%	HINTON2(W) takes a matrix and plots the Hinton diagram.
%
%   hinton2(color, w)
%   ? color:  MxN matrix corresponding to color scale
%   ? w:  MxN matrix corresponding to weights (sizes of boxes)
%
%	H = HINTON(NET) also returns the figure handle H which can be used,
%	for instance, to delete the  figure when it is no longer needed.
%
%	To print the figure correctly in black and white, you should call
%	SET(H, 'INVERTHARDCOPY', 'OFF') before printing.
%
%   Code modified by Joshua D. Salvi

% Maximum figure size
xmax = 1024; ymax = 1024;

% Offset bottom left hand corner
x01 = 40; y01 = 40;
x02 = 80; y02 = 80;

% Need to allow 5 pixels border for window frame: but 30 at top
border = 5;
top_border = 30;

ymax = ymax - top_border;
xmax = xmax - border;

% First layer

[xvals, yvals,col] = hintmat(w);
color = reshape(color,size(w,1)*size(w,2),1);

% Try to preserve aspect ratio approximately
if (8*size(w, 1) < 6*size(w, 2))
  delx = xmax; dely = xmax*size(w, 1)/(size(w, 2));
else
  delx = ymax*size(w, 2)/size(w, 1); dely = ymax;
end

h = figure('Color', [1 1 1], ...
  'Name', 'Hinton diagram', ...
  'NumberTitle', 'off', ...
  'Units', 'pixels', ...
  'Position', [x01 y01 delx dely]);
set(gca, 'Visible', 'off', 'Position', [0 0 1 1]);
hold on
patch(xvals', yvals', color', 'Edgecolor', 'none');
axis equal;

end

function [xvals, yvals, color] = hintmat(w)
%HINTMAT Evaluates the coordinates of the patches for a Hinton diagram.
%
%	Description
%	[xvals, yvals, color] = hintmat(w)
%	  takes a matrix W and returns coordinates XVALS, YVALS for the
%	patches comrising the Hinton diagram, together with a vector COLOR
%	labelling the color (black or white) of the corresponding elements
%	according to their sign.
%
%	See also
%	HINTON
%

%	Copyright (c) Ian T Nabney (1996-2001)

% Set scale to be up to 0.9 of maximum absolute weight value, where scale
% defined so that area of box proportional to weight value.

w = flipud(w);
[nrows, ncols] = size(w);

scale = 0.45*sqrt(abs(w)/max(max(abs(w))));
scale = scale(:);
color = 0.5*((w(:)) + 3);

delx = 1;
dely = 1;
[X, Y] = meshgrid(0.5*delx:delx:(ncols-0.5*delx), 0.5*dely:dely:(nrows-0.5*dely));

% Now convert from matrix format to column vector format, and then duplicate
% columns with appropriate offsets determined by normalized weight magnitudes. 

xtemp = X(:);
ytemp = Y(:);

xvals = [xtemp-delx*scale, xtemp+delx*scale, ...
         xtemp+delx*scale, xtemp-delx*scale];
yvals = [ytemp-dely*scale, ytemp-dely*scale, ...
         ytemp+dely*scale, ytemp+dely*scale];
     
end
