function y = downsample(x,N,varargin)
%DOWNSAMPLE Downsample input signal.
%   DOWNSAMPLE(X,N) downsamples input signal X by keeping every
%   N-th sample starting with the first. If X is a matrix, the
%   downsampling is done along the columns of X.
%
%   DOWNSAMPLE(X,N,PHASE) specifies an optional sample offset.
%   PHASE must be an integer in the range [0, N-1].
%
%   % Example 1:
%   %   Decrease the sampling rate of a sequence by 3.
%
%   x = [1 2 3 4 5 6 7 8 9 10];
%   y = downsample(x,3)
%
%   % Example 2:
%   %   Decrease the sampling rate of the sequence by 3 and add a 
%   %   phase offset of 2.
%
%   x = [1 2 3 4 5 6 7 8 9 10];
%   y = downsample(x,3,2)
%
%   % Example 3:
%   %   Decrease the sampling rate of a matrix by 3.
%
%   x = [1 2 3; 4 5 6; 7 8 9; 10 11 12];
%   y = downsample(x,3)
%
%   See also UPSAMPLE, UPFIRDN, INTERP, DECIMATE, RESAMPLE.

%   Copyright 1988-2019 The MathWorks, Inc.
%#codegen

narginchk(2,3)

if isempty(varargin)
    phase = 0;
else
    phase = varargin{1};
end

% Input validation
% Validate x
coder.internal.assert(~isempty(x),'signal:downsample:Nonempty');
coder.internal.assert(isnumeric(x) || islogical(x) || ischar(x),'signal:downsample:InvalidType');
% Validate phase and downsample factor
validateattributes(N,{'numeric'},{'scalar','nonempty','finite','real','positive','integer'},'downsample','N');
validateattributes(phase,{'numeric'},{'scalar','nonempty','integer','nonnegative','<=',N-1},'downsample','PHASE');

% Scalar lockdown
N = double(N(1));
phase = phase(1);

% Find the leading non-singleton dimension
if coder.target('MATLAB')
    % Save original size of x (possibly N-D)
    sizeX = size(x);
    
    dim = find(sizeX~=1,1,'first');
    if isempty(dim)
        dim = 1;
    end    
else
    % for codegen
    dim = coder.internal.nonSingletonDim(x);
    
    % Save original size of x (possibly N-D)
    sizeX = coder.internal.indexInt(size(x));
end

nshifts = dim - 1;
lshift = circshift(sizeX,-nshifts);
ytemp = reshape(x,lshift);    

% Downsample on the leading non-singleton dimension
ytemp1 = ytemp(phase+1:N:end,:);

% Update the new downsampled dimension
sizeX(1,nshifts+1) = size(ytemp1,1);

% Restore to the original N-D dimensions
y = reshape(ytemp1,sizeX);

end

% [EOF] 

% LocalWords:  downsamples th lockdown downsampled
