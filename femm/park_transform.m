function x_out = park_transform(x, theta, p, inverse)
% PARK_TRANSFORM - Transformation de Park directe ou inverse (format Nx2)
%
%   x       : matrice Nx2 (xalpha, xbeta) ou (xd, xq)
%   theta   : vecteur Nx1 ou 1xN (même longueur que x)
%   p       : nombre de paires de pôles
%   inverse : booléen (false = directe, true = inverse)
%
%   x_out   : matrice Nx2 (xd, xq) ou (xalpha, xbeta)

    if nargin < 4
        inverse = false;
    end

    if size(x,2) ~= 2
        error('x doit être une matrice Nx2');
    end

    N = size(x,1);

    if numel(theta) ~= N
        error('theta doit avoir autant d''éléments que de lignes de x');
    end

    theta = reshape(theta, [], 1);  % Nx1
    angle_p = p * theta;

    c = cos(angle_p);  % Nx1
    s = sin(angle_p);  % Nx1

    % Composantes
    xx = x(:,1);  % xalpha ou xd
    yy = x(:,2);  % xbeta ou xq

    if ~inverse  % Park direct
        x_out = [ c .* xx + s .* yy,  -s .* xx + c .* yy ];  % Nx2
    else         % Park inverse
        x_out = [ c .* xx - s .* yy,   s .* xx + c .* yy ];  % Nx2
    end
end
