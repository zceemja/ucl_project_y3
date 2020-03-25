close all; clc
load 'risc8.mat' risc8
load 'oisc8.mat' oisc8

data = table2array(risc8(:,2:end));
names = table2array(risc8(:,1));
gnames = risc8.Properties.VariableNames(2:end);

data2 = table2array(oisc8(:,2:end));
names2 = table2array(oisc8(:,1));
gnames2 = oisc8.Properties.VariableNames(2:end);
gnames2_dst = erase(gnames2(1:2:end),"dst");
gnames2_src = erase(gnames2(2:2:end),"src");

x = categorical(gnames);
x = reordercats(x,gnames);

% t = tiledlayout(5,2);
for i=1:10
    i=4;
    d0 = data(6,:);
    d1 = data2(i,:);
    d_src = d1(1:2:end);
    d_dst = d1(2:2:end);
    
    figure;
    pie(d0(~d0==0))
    legend(gnames(~d0==0), "interpreter", "None")
    title("RISC 'multiply 16bit' function instruction composition");
    
    figure;
    pie(d_src(~d_src==0))
    legend(gnames2_src(~d_src==0), "interpreter", "None")
    title("OISC 'multiply 16bit' function src. instruction composition");
    
    figure
    pie(d_dst(~d_dst==0))
    legend(gnames2_dst(~d_dst==0), "interpreter", "None")
    title("OISC 'multiply 16bit' function dest. instruction composition");
    break
end
