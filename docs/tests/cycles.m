close all
%set(0,'defaulttextinterpreter','latex')
%set(0,'DefaultTextFontname', 'CMU Serif')
%set(0,'DefaultAxesFontName', 'CMU Serif')
%text(0.5, 0.8, '\textsf{sans serif}','interpreter','latex')

    %NaN 963;  div ffff/0001
    %NaN 663;  div ffff/ffff
    %NaN 598;  div 0001/ffff

data = [
    208 204
    361 534
    618 1076
    59 99
    27 49
    52 55
];
grid on
legend
B = bar(1:length(data),data);
x_labels = [
    {'Print Decimal 0000h'}
    {'Print Decimal FFFFh'}
    {'Modulus FFFFh%0001h'}
    {'Modulus FFFFh%FFFFh'}
    {'Modulus 0001h%FFFFh'}
	{'Multiply 16bit'}
];
set(gca,'XTickLabel', x_labels);
%x_labels = [
    %{'\begin{tabular}{r}Divide\\FFFFh/0001h\end{tabular}'}
    %{'\begin{tabular}{r}Divide\\FFFFh/FFFFh\end{tabular}'}
    %{'\begin{tabular}{r}Divide\\0001h/FFFFh\end{tabular}'}
    %{'\begin{tabular}{r}Modulus\\FFFFh\%0001h\end{tabular}'}
    %{'\begin{tabular}{r}Modulus\\FFFFh\%FFFFh\end{tabular}'}
    %{'\begin{tabular}{r}Modulus\\0001h\%FFFFh\end{tabular}'}
    %{'\begin{tabular}{r}Multiply 16bit\end{tabular}'}
%];
%set(gca,'XTickLabel', x_labels, 'TickLabelInterpreter', 'latex')
title("Processor cycles per function")
ylabel("Numer of cycles")
xtickangle(30);
xtips1 = [1:length(data)] - 0.21;
ytips1 = B(1).YData;
labels1 = string(B(1).YData);
text(xtips1,ytips1,labels1,'HorizontalAlignment','center','VerticalAlignment','bottom');
xtips2 = [1:length(data)] + 0.25;
ytips2 = B(2).YData;
labels2 = string(B(2).YData);
text(xtips2,ytips2,labels2,'HorizontalAlignment','center','VerticalAlignment','bottom');

legend("RISC", "OISC");
grid on
%set(gcf, 'Color', 'None')

%%
data = [
    20.316 3.474 26.438 2.033 14.705
    66.126 3.998 48.040 3.542 23.044
]';
grid on
legend
B = bar(1:length(data),data);
x_labels = [
    {'Prime Numbers'}
    {'Multiply'}
    {'Modulo 0010h'}
    {'Modulo FFFFh'}
    {'BCD'}
];
set(gca,'XTickLabel', x_labels);
ylabel('Time (s)')
title("Time taken for each benchmark")
grid on
legend("RISC", "OISC");
xtickangle(30);

%%
figure
P = [359.09 360.851 360.732];
Pstd = [0.245 0.239 0.223];
bar(1:3,P)                
hold on
er = errorbar(1:3, P, -Pstd./2,+Pstd./2); 
er.Color = [0 0 0];
er.LineStyle = 'none';
set(gca,'xticklabel',{'None'; 'RISC'; 'OISC'})
ylabel("Power (mW)")
title("Processor power consumtion")