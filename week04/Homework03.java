package java0.conc0303;

import java.util.concurrent.*;

/**
 * 本周作业：（必做）思考有多少种方式，在main函数启动一个新线程或线程池，
 * 异步运行一个方法，拿到这个方法的返回值后，退出主线程？
 * 写出你的方法，越多越好，提交到github。
 *
 * 一个简单的代码参考：
 */
public class Homework03 {
    
    public static void main(String[] args) {
        
        long start = System.currentTimeMillis();

        // 在这里创建一个线程或线程池，
        // 异步执行 下面方法

        //1
//        new MyThread(start).start();

        //2
//        new Thread(() -> {
//            int result = sum();
//            System.out.println(Thread.currentThread() + "异步计算结果为："+result);
//            System.out.println(Thread.currentThread() + "使用时间："+ (System.currentTimeMillis()-start) + " ms");
//        }).start();

        //3
//        ExecutorService executor = Executors.newCachedThreadPool();
//        Future<Integer> result = executor.submit(() -> sum());
//        executor.shutdown();
//        try {
//            System.out.println(Thread.currentThread() + "异步计算结果为："+result.get());
//        } catch (InterruptedException e) {
//            e.printStackTrace();
//        } catch (ExecutionException e) {
//            e.printStackTrace();
//        }
//        System.out.println(Thread.currentThread() + "使用时间："+ (System.currentTimeMillis()-start) + " ms");

        //4
        ExecutorService executor2 = Executors.newCachedThreadPool();
        executor2.execute(() -> {
            int result1 = sum();
            System.out.println(Thread.currentThread() + "异步计算结果为："+ result1);
            System.out.println(Thread.currentThread() + "使用时间："+ (System.currentTimeMillis()-start) + " ms");
        });
        executor2.shutdown();




    }
    
    private static int sum() {
        return fibo(36);
    }
    
    private static int fibo(int a) {
        if ( a < 2) 
            return 1;
        return fibo(a-1) + fibo(a-2);
    }

    public static class MyThread extends Thread{
        private long start;
        public MyThread(long start){
            this.start = start;
        }
        public void run(){
            int result = sum();
            System.out.println(Thread.currentThread() + "异步计算结果为："+result);
            System.out.println(Thread.currentThread() + "使用时间："+ (System.currentTimeMillis()-start) + " ms");
        }
    }
}
