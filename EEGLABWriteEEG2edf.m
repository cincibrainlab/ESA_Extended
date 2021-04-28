function EEGLABWriteEEG2edf(EEG, strSaveDir)
% pop_writeeeg - write EEGLAB dataset to disk in EDF/GDF or BDF format
%
% pop_writeeeg( EEG ) % pops up a window
% pop_writeeeg( EEG, filename, 'key', 'val' )
%
% Inputs:
%  EEG        - EEGLAB dataset
%  filename   - [string] filename
%
% Optional keys (same as writeeeg):
%  'TYPE'         - ['GDF'|'EDF'|'BDF'|'CFWB'|'CNT'] file format for writing
%                   default is 'EDF'.
%  See writeeeg for more information
%
% Author: Arnaud Delorme, SCCN, UCSD/CERCO, 2009
%         Based on BIOSIG, sopen and swrite

% Copyright (C) 22 March 2002 Arnaud Delorme, Salk Institute, arno@salk.edu
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

% command = '';
 
% Check for BIOSIG Toolbox

global PLUGINLIST
 if ~isempty(PLUGINLIST) && ~any(strcmp({PLUGINLIST.plugin}','Biosig'))
     fprintf(2,'pop_writeeeg error: This function requires you to install <a href="http://biosig.sourceforge.net/index.html">BIOSIG Toolbox</a> plug-in. \n');

 elseif isempty(PLUGINLIST)
     warning('pop_writeeeg check for <a href="http://biosig.sourceforge.net/index.html">BIOSIG Toolbox</a> could not be performed.');
 end

% if nargin < 2
%     if EEG.trials > 1
%         res = questdlg2( [ 'This dataset contains data epochs.' 10 'Do you want to export the concatenated' 10 'data epochs?' ], '', 'No', 'Yes', 'Yes');
%         if strcmpi(res, 'No')
%             return;
%         end;
%     end;
    
% 	% ask user
% 	[strSaveDir, filepath] = uiputfile('*.*', 'Enter a file name -- pop_writeeeg()'); 
% 	if strSaveDir == 0 return; end;
% 	strSaveDir = fullfile(filepath,strSaveDir);
    
%     % file format
%     % -----------
%     fileformats = { 'EDF' 'GDF' 'BDF' };
%     uilist = { { 'style' 'text' 'String' 'File format' } ...
%                { 'style' 'listbox' 'string' strvcat(fileformats) 'value' 1 } };
%     geom = [1 1];
%     result = inputgui( 'geometry', geom, 'uilist', uilist, 'helpcom', 'pophelp(''pop_writeeeg'')', ...
%                      'title', 'Write data using BIOSIG -- pop_writeeeg()', 'geomvert', [1 2.5]);
%     if length(result) == 0 return; end;
% keyboard; 
%     options = { 'TYPE' fileformats{result{1}} };
    options = { 'TYPE' 'EDF' };
% else
%     options = varargin;
% end;

warning('off', 'MATLAB:intConvertNonIntVal');
if ~isempty(EEG.chanlocs)
    tmpchanlocs = EEG.chanlocs;
    writeeeg(strSaveDir, EEG.data(:,:), EEG.srate, 'label', { tmpchanlocs.labels }, 'EVENT', EEG.event, options{:});
else
    writeeeg(strSaveDir, EEG.data(:,:), EEG.srate, 'EVENT', EEG.event, options{:});
end
warning('on', 'MATLAB:intConvertNonIntVal');

% command = sprintf('pop_writeeeg(EEG, ''%s'', %s);', strSaveDir, vararg2str(options)); 

% return;

end
