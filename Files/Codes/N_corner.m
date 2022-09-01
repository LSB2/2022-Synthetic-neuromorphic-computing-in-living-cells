clc
close all
%choose where to save the images:                                                      
cd('C:\Users\rmouna\Desktop\Matlab code New\Facs Data MAtlab 2022\Review experiments Matlab')
                                                                                                    
%enter facs data file loaction:                   
filelocation=('C:\Users\rmouna\Desktop\Matlab code New\Facs Data MAtlab 2022\Exp_20220426_1_5G');     

%enter filename (without the well labels):
filenamee='03-Well-';

ss=strcat(filelocation,'\',filenamee);

%enter well labels:
%
c={ '2'  '5' };  %columns labels                                 
r=[ 'A'  'F' ];  %rows labels                                   
                                                                            
%set the wells contents and inducer name:
    %the inducer that changes from column to column                              
        %inducer name
            name_Inducer_C='IPTG';     
        %inducer concentraion
            Inducer_C={ 
                        'IPTG=1000.00 然'
                        'IPTG=1000.00 然'
                        'IPTG=1000.00 然'
                        'IPTG=125.0 然'
                       
                        };	
                        	
                         
        %concentraions units
            Inducer_CU=' 然 ';                       
            
    %the inducer that changes from  from row to row
        %inducer name
            name_Inducer_R='aTc';
        %inducer concentratin
            Inducer_R={ 
                        'aTc=50.0 ng/ml'
                        'aTc=6.5 ng/ml'

                                           
                        };
        %concentrarion units
            Inducer_RU={'ng/ml'};    
%    
% Inducer_C=[cell2mat(Inducer_C') cell2mat(repmat(Inducer_CU,length(Inducer_C),1))];
% Inducer_CC=cellstr((Inducer_C));                                                                                                    
% Inducer_R=[cell2mat((Inducer_R')) cell2mat(repmat(Inducer_RU,length(Inducer_R),1))];
% Inducer_RR=cellstr((Inducer_R));
 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for z=[1 2]
    if(z==2)
        x=r;
        r=c;
        c=x;
        x=Inducer_R;
        Inducer_R=Inducer_C;
        Inducer_C=x;
%         x=Inducer_RR;
%         Inducer_RR=Inducer_CC;
%         Inducer_CC=x;
        x=name_Inducer_R;
        name_Inducer_R=name_Inducer_C;
        name_Inducer_C=x;
    end
%open the .fcs file for a specific well,... here i used a function that i
    %downloaded from mathworks
    for i=1:length(r)
            for j=1:length(c)
                if(z==1)
%    
                s=strcat(ss,r(i),c(j),'.fcs');
                end
                if(z==2)
                 s=strcat(ss,c(j),r(i),'.fcs');
                end
                s=cell2mat(s);
                [fcsdat, fcshdr, fcsdatscaled] = fca_readfcs(s);
                %take histogram values
                %choose which data you wish to plot (a column vector in fcsdat)
%                 [a,b]=hist(fcsdat(:,7),10000);
%                 b=b;
%                 b=b;
                a=sort((double(fcsdat(:,6)))); %gfp=6 OR Mcherry=8
                b=logspace(0,log10(max(a)),400);
                aa=zeros(1,length(b)); %
                for h=2:length(b)
                    aa(h)=sum((a>b(h-1)).*(a<b(h)));
                end
                
av=aa;
%                 % remove negative values
%                 a=nonzeros((b>0).*(a+eps));
%                 b=nonzeros((b>0).*b);

%                 smoothing
%                     averaging
%                     N=10;
%                     av=zeros(length(a)-N+1,1);
%                     for k=1:N
%                     av=av+a(k:end-N+k);
%                     end
%                     av=av/N;
%                     av=av/max(av);
%                     hold all
%                     aa=av;
% av=a;
                    %loess smooth
                    aa=smooth(b(1:length(av)),av,0.15,'loess');
%                     aa=av;
max(aa)
                    aa=aa/max(aa);
% aa=a/max(a);
                %plotting
                hf=figure(2);
                hold on
                ccolor=[0.1 0.4 0.7; %BLUE
                        0.87 0.45 0; %ORANGE
                        1 0.7 0;     %YELLOW
                        0.5 0.1 1;   %PURPLE
                        0.4 0.65 0;  %GREEN
                        0.4 0.8 0.89;%CYAN
                        0.65 0.1 0.1;%BORDO
                        1 0.5 1;     %PINK
                        0.6 0.6 0.6; %GRAY
                        0.7 0.4 0.1; %BROWN
                        1 0.5 0.5;   %JESMANI
                        0.7 1 0;];   %PHOSPHOR
                plot(b(1:length(aa)),aa,'linewidth',2,'color',ccolor(j,:))
            end
            %after this loop has ended, we have multiple plots for a constant
            %column and varying rows (ot vice reversa),
            %now we set the figure's properties 
            set(gca, 'XScale', 'log')
            set(hf,'position',[680 558 760 420])%set figure size
            
%             sss=[Inducer_RR(i) '  '  name_Inducer_R];
%             sss=cell2mat(sss);
%             title(sss,'FontSize',10)
            ylabel('Normalized cell count (%)','FontSize',14)
            xlabel('Flouresence [a.u.]','FontSize',14)
            xlim([100 10000000])
            ylim([-0.1 1.1])
                %these 2 loops here are important for the LEGEND:
            legend(Inducer_C,'location','northeastoutside','fontsize',12)
            %save figure
            figname=strcat(r(i),'.emf');
            if isequal(class(figname),class({1}))
                figname=cell2mat(figname);
            end
 
            saveas(hf,figname)
            close all
    end

end