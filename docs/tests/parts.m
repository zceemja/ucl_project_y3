close all; clc
% reportrisc = csvread('report_risc.csv');
% reportoisc = csvread('report_oisc.csv');
% load 'risc8.mat' risc8
% load 'oisc8.mat' oisc8

data = table2array(reportrisc(:,2:end-1));
names = table2array(reportrisc(:,1));
gnames = reportrisc.Properties.VariableNames(2:end-1);
data = data-data(6,:);
data(6,:) = [];
data(1,:) = [];

data2 = table2array(reportoisc(:,2:end-1));
data2 = data2-data2(6,:); data2(data2<0)=0;
data2(6,:) = [];
data2(1,:) = [];

names2 = table2array(reportoisc(:,1));
gnames2 = reportoisc.Properties.VariableNames(2:end-1);
gnames2_dst = erase(gnames2(1:2:end),"dst");
gnames2_src = erase(gnames2(2:2:end),"src");

namesf = {
%     "16bit division 0001h / 0001h";
    "16bit Modulo 0001h % FFFFh";
    "16bit Modulo FFFFh % 0001h";
    "16bit Modulo FFFFh % FFFFh";
    "16bit Multiplication";
%     "test functions";
    "Print Character";
    "Print 16bit unsigned int FFFFh";
    "Print 8bit unsigned int 00h";
    "Print 8bit unsigned int FFh";
};

d3names = {'Mod 0001h % FFFFh' 'Mod FFFFh % 0001h' ...
    'Mod FFFFh % FFFFh' '16bit multiply' ...
    'Print char' 'Print uint16 FFFFh' ...
    'Print uint8 00h' 'Print uint8 FFh'};
x2 = categorical(d3names);
x2 = reordercats(x2,d3names); 
data3 = [table2array(reportrisc(:,end))'; table2array(reportoisc(:,end))']';
data3(6,:) = [];
data3(1,:) = [];
bar(x2, data3, 1);
grid on
ylabel('Program size in bits')
legend('RISC', 'OISC')
xtickangle(60)
title('Benchmark functions effective program size')
%%

x = categorical(gnames);
x = reordercats(x,gnames);
% 
% t = tiledlayout(5,2);
[ha, pos] = tight_subplot(4,2,[.05 .05],[.15 .05],[.07 .01]);

for i=1:8
    axes(ha(i));
%     subplot(4,2,i)
    d0 = data(i,:);
    d1 = data2(i,:);
    d_src = d1(1:2:end);
    d_dst = d1(2:2:end);
    B = bar(x, [d0; d_src; d_dst]', 1);
    if mod(i,2)==1
        ylabel('Instructions')
    end
    grid on
    title([namesf(i)])
%     set(gcf,'Position',[100 100 500 300])
end
set(ha(1:6),'XTickLabel','');
legend({'RISC', 'OISC Destination', 'OISC Source'})




%%

OISCF = 1705;
RISCF = 3218;
% ALU, MEM
x = categorical({'RISC', 'OISC'});
y0 = [
 293 RISCF-2845 RISCF-2563 RISCF-((RISCF-2845) + (RISCF-2563))-293;
 293 486 225 701;
];

bar(x, y0, 'stacked');
legend('COMMON', 'ALU', 'MEMORY', 'OTHER')
grid on
ylabel("Logic elements")
title("Processors FPGA logic element composition")

figure
y1 = [
 170 1 407-315 144;
 170 142 86 328;
];
bar(x, y1, 'stacked');
legend('COMMON', 'ALU', 'MEMORY', 'OTHER')
grid on
ylabel("Registers")
title("Processors FPGA register usage composition")


% EMPTY Processor
%Total logic elements	293 / 22,320 ( 1 % )  // 294?? 
%Total registers	170

% RISC FULL
%Total logic elements	3,218 / 22,320 ( 14 % )
%Total registers	407

% RISC without ALU
%Total logic elements	2,845 / 22,320 ( 13 % )
%Total registers	406

% RISC without Memory
%Total logic elements	2,563 / 22,320 ( 11 % )
%Total registers	315

%

%OISC without rom
%Total logic elements	291 / 22,320 ( 1 % )
%Total registers	170

% OISC FULL
%Total logic elements	1,705 / 22,320 ( 8 % )
%Total registers	726
%Total memory bits	93,184 / 608,256 ( 15 % )
%Embedded Multiplier 9-bit elements	1 / 132 ( < 1 % )

% OISC without ALU
%Total logic elements	1,219 / 22,320 ( 5 % )
%Total registers	584
%Total memory bits	93,184 / 608,256 ( 15 % )

% OISC without mem/stack logic
%Total logic elements	1,480 / 22,320 ( 7 % )
%Total registers	640
%Total memory bits	93,184 / 608,256 ( 15 % )
