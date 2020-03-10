close all
%set(0,'defaulttextinterpreter','latex')
%set(0,'DefaultTextFontname', 'CMU Serif')
%set(0,'DefaultAxesFontName', 'CMU Serif')
%text(0.5, 0.8, '\textsf{sans serif}','interpreter','latex')
data = [
    NaN 963;
    NaN 663;
    NaN 598;
    618 1076;
    59 99;
    27 49;
    52 55];
grid on
legend
B = bar(1:7,data);
x_labels{1} = sprintf('Divide FFFFh/0001h');
x_labels{2} = sprintf('Divide FFFFh/FFFFh');
x_labels{3} = sprintf('Divide 0001h/FFFFh');
x_labels{4} = sprintf('Module FFFFh/0001h');
x_labels{5} = sprintf('Module FFFFh/FFFFh');
x_labels{6} = sprintf('Module 0001h/FFFFh');
x_labels{7} = sprintf('Multiply 16bit');
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
xtips1 = [1:7] - 0.21;
ytips1 = B(1).YData;
labels1 = string(B(1).YData);
text(xtips1,ytips1,labels1,'HorizontalAlignment','center','VerticalAlignment','bottom');
xtips2 = [1:7] + 0.21;
ytips2 = B(2).YData;
labels2 = string(B(2).YData);
text(xtips2,ytips2,labels2,'HorizontalAlignment','center','VerticalAlignment','bottom');

legend("RISC", "OISC");
grid on
%set(gcf, 'Color', 'None')


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