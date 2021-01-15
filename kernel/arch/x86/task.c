#include <paging.h>
#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

struct as {
    unsigned int gs, fs, es, ds;
    unsigned int edi, esi, ebp, esp, ebx, edx, ecx, eax;
    unsigned int int_no, err_code;
    unsigned int eip, cs, eflags, useresp, ss;
};

typedef enum process_level {
    USER, KERNEL
} process_level_t;

typedef struct process {
    char* name;
    arch_cpu_state_t* registers;
    page_directory_t* page_directory;
    void* kernel_stack;
    process_level_t level;
} process_t;

typedef struct linkedlist_node {
    void* ptr;
    struct linkedlist_node* next, *prev;
} linkedlist_node_t;

typedef struct linkedlist {
    linkedlist_node_t* head, *tail;
    size_t size;
} linkedlist_t;

typedef linkedlist_t queue_t;

linkedlist_node_t *make_node(void *ptr, linkedlist_node_t *prev, linkedlist_node_t *next);

linkedlist_node_t* get_node(linkedlist_t *list, uint32_t i);

linkedlist_t *linkedlist_create() {
    linkedlist_t* list = kmalloc(sizeof(linkedlist_t));
    if(list) {
        list->head = list->tail = NULL;
        list->size = 0;
    }
    return list;
}

bool linkedlist_add(linkedlist_t *list, void *ptr) {
    if(list->size == INT32_MAX) return false;
    linkedlist_node_t* node = make_node(ptr, list->tail, NULL);
    if(!node) return false;
    if(list->head && list->tail) list->tail->next = node;
    else list->head = node;
    list->tail = node;
    list->size++;
    return true;
}

void *linkedlist_get(linkedlist_t *list, uint32_t i) {
    if(list->size <= i) return NULL;
    return get_node(list, i)->ptr;
}

linkedlist_node_t* get_node(linkedlist_t *list, uint32_t i) {
    linkedlist_node_t* node = list->head;
    for (uint32_t j = 0; j < i; ++j) node = node->next;
    return node;
}

size_t linkedlist_size(linkedlist_t *list) {
    return list->size;
}

bool linkedlist_remove(linkedlist_t *list, uint32_t i) {
    if(list->size <= i) return false;
    linkedlist_node_t* node = get_node(list, i);
    if(node->next) node->next->prev = node->prev;
    if(node->prev) node->prev->next = node->next;
    if(i == 0) list->head = node->next;
    if(i == list->size - 1) list->tail = node->prev;
    list->size--;
    // TODO kfree(node);
    return true;
}

bool linkedlist_insert(linkedlist_t *list, void *ptr, uint32_t i) {
    if(linkedlist_size(list) >= UINT32_MAX || i > linkedlist_size(list))
        return false;
    linkedlist_node_t* node = make_node(ptr, NULL, NULL);
    if(!node) return false;
    if(i == 0) {
        node->next = list->head;
        list->head->prev = node;
        list->head = node;
    } else if (i == linkedlist_size(list)) linkedlist_add(list, ptr);
    else {
        linkedlist_node_t* prev_node = get_node(list, i - 1), * next_node = prev_node->next;
        prev_node->next = node;
        node->prev = prev_node;
        next_node->prev = node;
        node->next = prev_node;
    }
    list->size++;
    return 0;
}

linkedlist_node_t *make_node(void *ptr, linkedlist_node_t *prev, linkedlist_node_t *next) {
    linkedlist_node_t* node = kmalloc(sizeof(linkedlist_node_t));
    if(node) {
        node->next = next;
        node->prev = prev;
        node->ptr = ptr;
    }
    return node;
}


queue_t *queue_create() {
    return linkedlist_create();
}

bool queue_enqueue(queue_t *queue, void *ptr) {
    return linkedlist_add(queue, ptr);
}

void *queue_dequeue(queue_t *queue) {
    if(linkedlist_size(queue) >= 1) {
        void *item = linkedlist_get(queue, 0);
        linkedlist_remove(queue, 0);
        return item;
    }
    return NULL;
}

size_t queue_size(queue_t *queue) {
    return linkedlist_size(queue);
}


process_t *process_create(char* name, arch_cpu_state_t *regs, page_directory_t *page_dir, void *kernel_stack, process_level_t level) {
    process_t* process = kmalloc(sizeof(process_t));
    process->name = name;
    process->registers = regs;
    process->page_directory = page_dir;
    process->kernel_stack = kernel_stack;
    process->level = level;
}

queue_t* process_queue = NULL;
process_t* current_process = NULL;

void on_tick(arch_cpu_state_t* regs) {
    // Check if there are any processes to switch to
    if(queue_size(process_queue) == 0) return;
    if(current_process) {
        // Save the process' state for later retrieval
        arch_save_state(current_process->registers, regs);
        // Re-queue the process
        queue_enqueue(process_queue, current_process);
    }
    // Get the next process to run
    process_t* next_process = queue_dequeue(process_queue);
    // Put its state onto the stack for the interrupt handler to restore
    arch_save_state(regs, next_process->registers);
    set_page_directory(next_process->page_directory);
}

void multitasking_init() {
    process_queue = queue_create();
    register_interrupt_handler(32, on_tick);
}

void multitasking_schedule(process_t *process) {
    queue_enqueue(process_queue, process);
}

extern void* stack_bottom;

arch_cpu_state_t task_one;
arch_cpu_state_t task_two;

void do_task_one() {
    while(true) {
        printk("A");
        arch_switch_task(&task_one, &task_two);
    }
}

void startsched()
{
    uint32_t* task_one_stack = kmalloc(1024);
    task_one.ebp = (uint32_t)task_one_stack;
    task_one.esp = (uint32_t)task_one_stack + 1024 - 4*4;
    task_one.edi = 0;
    task_one.ebx = 0;
    task_one.esi = 0;
    task_two.ebp = (uint32_t)stack_bottom;
    task_two.esp = arch_get_stack_pointer();
    task_two.edi = 0;
    task_two.ebx = 0;
    task_two.esi = 0;

    // These values are popped off by arch_switch_task before returning
    task_one_stack[1024/4 - 4] = task_one.ebp;
    task_one_stack[1024/4 - 3] = task_one.edi;
    task_one_stack[1024/4 - 2] = task_one.esi;
    task_one_stack[1024/4 - 1] = task_one.ebx;
    // The address for arch_switch_task to return to
    task_one_stack[1024/4] = (uint32_t)do_task_one;
    arch_switch_task(&task_two, &task_one);

    while(true) {
        printk("B");
        arch_switch_task(&task_two, &task_one);
    }
}