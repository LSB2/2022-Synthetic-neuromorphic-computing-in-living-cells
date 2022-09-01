function [fcsdat, fcshdr, fcsdatscaled] = fca_readfcs(filename)
% [fcsdat, fcshdr, fcsdatscaled] = fca_readfcs(filename);
%
% Read FCS 2.0 and FCS 3.0 type flow cytometry data file and put the list mode  
% parameters to the fcsdat array with size of [NumOfPar TotalEvents]. 
% Some important header data are stored in the fcshdr structure:
% TotalEvents, NumOfPar, starttime, stoptime and specific info for parameters
% as name, range, bitdepth, logscale(yes-no) and number of decades.
%
% [fcsdat, fcshdr] = fca_readfcs;
% Without filename input the user can select the desired file
% using the standard open file dialog box.
%
% [fcsdat, fcshdr, fcsdatscaled] = fca_readfcs(filename);
% Supplying the third output the fcsdatscaled array contains also the scaled     
% parameters. It might be useful for logscaled parameters, but no effect 
% in the case of linear parameters. The log scaling is the following
% operation for the "ith" parameter:  
% fcsdatscaled(:,i) = ...
%   10.^(fcsdat(:,i)/fcshdr.par(i).range*fcshdr.par(i).decade;);

% Ver 2.2
% 2006 / University of Debrecen, PET Center 
% Laszlo Balkay 
% balkay@pet.dote.hu


% if noarg was supplied
if nargin == 0
     [FileName, FilePath] = uigetfile('*.*','Select fcs2.0 file');
     filename = [FilePath,FileName];
     if FileName == 0;
          fcsdat = []; fcshdr = [];
          return;
     end
else
    filecheck = dir(filename);
    if size(filecheck,1) == 0
        hm = msgbox([filename,': The file does not exist!'], ...
            'FcAnalysis info','warn');
        fcsdat = []; fcshdr = [];
        return;
    end
end

% if filename arg. only contain PATH, set the default dir to this
% before issuing the uigetfile command. This is an option for the "fca"
% tool
[FilePath, FileNameMain, fext] = fileparts(filename);
FilePath = [FilePath filesep];
FileName = [FileNameMain, fext];
if  isempty(FileNameMain)
    currend_dir = cd;
    cd(FilePath);
    [FileName, FilePath] = uigetfile('*.*','Select FCS file');
     filename = [FilePath,FileName];
     if FileName == 0;
          fcsdat = []; fcshdr = [];
          return;
     end
     cd(currend_dir);
end

%fid = fopen(filename,'r','ieee-be');
fid = fopen(filename,'r','l');
fcsheader_1stline   = fread(fid,64,'char');
fcsheader_type = char(fcsheader_1stline(1:6)');
%
%reading the header
%
if strcmp(fcsheader_type,'FCS1.0')
    hm = msgbox('FCS 1.0 file type is not supported!','FcAnalysis info','warn');
    fcsdat = []; fcshdr = [];
    fclose(fid);
    return;
elseif  strcmp(fcsheader_type,'FCS2.0') || strcmp(fcsheader_type,'FCS3.0') % FCS2.0 or FCS3.0 types
    fcshdr.fcstype = fcsheader_type;
    FcsHeaderStartPos   = str2num(char(fcsheader_1stline(16:18)'));
    FcsHeaderStopPos    = str2num(char(fcsheader_1stline(23:26)'));
    FcsDataStartPos     = str2num(char(fcsheader_1stline(31:34)'));
    status = fseek(fid,FcsHeaderStartPos,'bof');
    fcsheader_main = fread(fid,FcsHeaderStopPos-FcsHeaderStartPos+1,'char');%read the main header
    warning off MATLAB:nonIntegerTruncatedInConversionToChar;
    fcshdr.filename = FileName;
    fcshdr.filepath = FilePath;
    if ~isempty(findstr(char(fcsheader_main'),'\$')) 
        mnemonic_separator = '\';% ordinary FCS2.0
    elseif ~isempty(findstr(char(fcsheader_main'),'!$')) 
        mnemonic_separator = '!';% Becton EPics DLM FCS2.0
    elseif ~isempty(findstr(char(fcsheader_main'),'|$')) 
        mnemonic_separator = '|';% CyAn Summit FCS3.0
    elseif ~isempty(findstr(char(fcsheader_main'),'@$')) 
        mnemonic_separator = '@';% CyAn Summit FCS3.0
    else 
        mnemonic_separator = 'FF';% FACSDiva type FCS2.0 or FCS3.0
    end
    fcshdr.TotalEvents = str2num(get_mnemonic_value('$TOT',fcsheader_main, mnemonic_separator));
    fcshdr.NumOfPar = str2num(get_mnemonic_value('$PAR',fcsheader_main, mnemonic_separator));
    for i=1:fcshdr.NumOfPar
        fcshdr.par(i).name = get_mnemonic_value(['$P',num2str(i),'N'],fcsheader_main, mnemonic_separator);
        fcshdr.par(i).range = str2num(get_mnemonic_value(['$P',num2str(i),'R'],fcsheader_main, mnemonic_separator));
        fcshdr.par(i).bit = str2num(get_mnemonic_value(['$P',num2str(i),'B'],fcsheader_main, mnemonic_separator));
        par_exponent= get_mnemonic_value(['$P',num2str(i),'E'],fcsheader_main, mnemonic_separator);
        fcshdr.par(i).decade = str2num(par_exponent(1));
        if fcshdr.par(i).decade == 0
            fcshdr.par(i).log = 0;
            fcshdr.par(i).logzero = 0;
        else
            fcshdr.par(i).log = 1;
            if str2num(par_exponent(findstr(par_exponent,',')+1:end)) == 0
                fcshdr.par(i).logzero = 1;
            else
                fcshdr.par(i).logzero = str2num(par_exponent(findstr(par_exponent,',')+1:end));
            end
        end
    end
    fcshdr.starttime = get_mnemonic_value('$BTIM',fcsheader_main, mnemonic_separator);
    fcshdr.stoptime = get_mnemonic_value('$ETIM',fcsheader_main, mnemonic_separator);
    fcshdr.cytometry = get_mnemonic_value('$CYT',fcsheader_main, mnemonic_separator);
    fcshdr.date = get_mnemonic_value('$DATE',fcsheader_main, mnemonic_separator);
    fcshdr.byteorder = get_mnemonic_value('$BYTEORD',fcsheader_main, mnemonic_separator);
    fcshdr.datatype = get_mnemonic_value('$DATATYPE',fcsheader_main, mnemonic_separator);
    fcshdr.system = get_mnemonic_value('$SYS',fcsheader_main, mnemonic_separator);
    fcshdr.project = get_mnemonic_value('$PROJ',fcsheader_main, mnemonic_separator);
    fcshdr.experiment = get_mnemonic_value('$EXP',fcsheader_main, mnemonic_separator);
    fcshdr.cells = get_mnemonic_value('$Cells',fcsheader_main, mnemonic_separator);
    fcshdr.creator = get_mnemonic_value('CREATOR',fcsheader_main, mnemonic_separator);
else
    hm = msgbox([FileName,': The file can not be read (Unsupported FCS type)'],'FcAnalysis info','warn');
    fcsdat = []; fcshdr = [];
    fclose(fid);
    return;
end
%
%reading the events
%
status = fseek(fid,FcsDataStartPos,'bof');
if strcmp(fcsheader_type,'FCS2.0')
    if strcmp(mnemonic_separator,'\') || strcmp(mnemonic_separator,'FF')%ordinary or FacsDIVA FCS2.0 
        if fcshdr.par(1).bit == 16
            fcsdat = uint16(fread(fid,[fcshdr.NumOfPar fcshdr.TotalEvents],'uint16')');
        elseif fcshdr.par(1).bit == 32
            fcsdat = (fread(fid,[fcshdr.NumOfPar fcshdr.TotalEvents],'uint32')');
        else 
            bittype = ['ubit',num2str(fcshdr.par(1).bit)];
            fcsdat = fread(fid,[fcshdr.NumOfPar fcshdr.TotalEvents],bittype, 'ieee-le')';
        end
    elseif strcmp(mnemonic_separator,'!');% Becton EPics DLM FCS2.0
        fcsdat_ = fread(fid,[fcshdr.NumOfPar fcshdr.TotalEvents],'uint16', 'ieee-le')';
        fcsdat = zeros(fcshdr.TotalEvents,fcshdr.NumOfPar);
        for i=1:fcshdr.NumOfPar
            bintmp = dec2bin(fcsdat_(:,i));
            fcsdat(:,i) = bin2dec(bintmp(:,7:16)); % only the first 10bit is valid for the parameter  
        end
    end
    fclose(fid);
elseif strcmp(fcsheader_type,'FCS3.0')
    if strcmp(mnemonic_separator,'|') % CyAn Summit FCS3.0
        fcsdat_ = (fread(fid,[fcshdr.NumOfPar fcshdr.TotalEvents],'uint16','ieee-le')');
        fcsdat = zeros(size(fcsdat_));
        new_xrange = 1024;
        for i=1:fcshdr.NumOfPar
            fcsdat(:,i) = fcsdat_(:,i)*new_xrange/fcshdr.par(i).range;
            fcshdr.par(i).range = new_xrange;
        end
    else % ordinary FCS 3.0
        fcsdat = fread(fid,[fcshdr.NumOfPar fcshdr.TotalEvents],'float32')';
    end
    fclose(fid);
end
%
%calculate the scaled events (for log scales)
%
fcsdatscaled = zeros(size(fcsdat));
for  i = 1 : fcshdr.NumOfPar
    Xlogdecade = fcshdr.par(i).decade;
    XChannelMax = fcshdr.par(i).range;
    Xlogvalatzero = fcshdr.par(i).logzero;
    if ~fcshdr.par(i).log
       fcsdatscaled(:,i)  = fcsdat(:,i);
    else
       fcsdatscaled(:,i) = Xlogvalatzero*10.^(fcsdat(:,i)/XChannelMax*Xlogdecade);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function mneval = get_mnemonic_value(mnemonic_name,fcsheader,mnemonic_separator)

if strcmp(mnemonic_separator,'\')  || strcmp(mnemonic_separator,'!') ...
        || strcmp(mnemonic_separator,'|') || strcmp(mnemonic_separator,'@')
    mnemonic_startpos = findstr(char(fcsheader'),mnemonic_name);
    if isempty(mnemonic_startpos)
        mneval = [];
        return;
    end
    mnemonic_length = length(mnemonic_name);
    mnemonic_stoppos = mnemonic_startpos + mnemonic_length;
    next_slashes = findstr(char(fcsheader(mnemonic_stoppos+1:end)'),mnemonic_separator);
    next_slash = next_slashes(1) + mnemonic_stoppos;

    mneval = char(fcsheader(mnemonic_stoppos+1:next_slash-1)');
elseif strcmp(mnemonic_separator,'FF')
    mnemonic_startpos = findstr(char(fcsheader'),mnemonic_name);
    if isempty(mnemonic_startpos)
        mneval = [];
        return;
    end
    mnemonic_length = length(mnemonic_name);
    mnemonic_stoppos = mnemonic_startpos + mnemonic_length ;
    next_formfeeds = find( fcsheader(mnemonic_stoppos+1:end) == 12);
    next_formfeed = next_formfeeds(1) + mnemonic_stoppos;

    mneval = char(fcsheader(mnemonic_stoppos + 1 : next_formfeed-1)');
end