close all
data = [
    0 963;
    0 663;
    0 598;
    0 1076;
    0 99;
    0 49;
    0 55];
grid on
legend
B = bar(1:7,data);
x_labels = [
    {'\begin{tabular}{r}\texttt{Divide}\\\texttt{FFFFh/0001h}\end{tabular}'}
    {'\begin{tabular}{r}\texttt{Divide}\\\texttt{FFFFh/FFFFh}\end{tabular}'}
    {'\begin{tabular}{r}\texttt{Divide}\\\texttt{0001h/FFFFh}\end{tabular}'}
    {'\begin{tabular}{r}\texttt{Modulus}\\\texttt{FFFFh\%0001h}\end{tabular}'}
    {'\begin{tabular}{r}\texttt{Modulus}\\\texttt{FFFFh\%FFFFh}\end{tabular}'}
    {'\begin{tabular}{r}\texttt{Modulus}\\\texttt{0001h\%FFFFh}\end{tabular}'}
    {'\begin{tabular}{r}\texttt{Multiply 16bit}\end{tabular}'}
];
set(gca,'XTickLabel', x_labels, 'TickLabelInterpreter', 'latex')
title("Power consumtion of implemented design on FPGA")
ylabel("Numer of cycles")
xtickangle(40);
xtips1 = [1:7] - 0.21;
ytips1 = B(1).YData;
labels1 = ['N/A'];
text(xtips1,ytips1,labels1,'HorizontalAlignment','center','VerticalAlignment','bottom');
xtips2 = [1:7] + 0.21;
ytips2 = B(2).YData;
labels2 = string(B(2).YData);
text(xtips2,ytips2,labels2,'HorizontalAlignment','center','VerticalAlignment','bottom');

legend("RISC", "OISC");
grid on


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
title("Power consumtion of implemented design on FPGA")