#include <stdio.h>
#include <string.h>
#include <sbi.h>
//OS�ں˳�ʼ������
int kern_init(void) __attribute__((noreturn)); //������

int kern_init(void) { 
    // edata: BSS�εĿ�ʼ��ַ��δ��ʼ�����ݶΣ�
    // end:   ���������ַ��BSS�εĽ�����ַ��
    extern char edata[], end[]; //�ⲿ����
    memset(edata, 0, end - edata);  //����BSS�Σ���edata��end֮����ڴ������ʼ��Ϊ0

    const char *message = "(THU.CST) os is loading ...\n"; //����������Ϣ
    cprintf("%s\n\n", message); //ʹ�ÿ���̨���������ӡ������Ϣ��cprintf��֮ǰ���ܹ��ĸ�ʽ���������
   while (1) //����ѭ��
        ;
}
