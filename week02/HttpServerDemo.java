package com.mengbo.demo;

import java.io.IOException;
import java.io.PrintWriter;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.concurrent.*;

public class HttpServerDemo {
    public static void main(String[] args) throws IOException {
        ServerSocket serverSocket = new ServerSocket(8801);

        //单线程
//        while(true){
//            Socket socket = serverSocket.accept();
//            service(socket);
//        }

        //多线程
//        while(true){
//            final Socket socket = serverSocket.accept();
//            new Thread(() -> {
//                try {
//                    service(socket);
//                } catch (IOException e) {
//                    e.printStackTrace();
//                }
//            }).start();
//        }

        //线程池
        ExecutorService executorService = Executors.newFixedThreadPool(Runtime.getRuntime().availableProcessors() + 2);
        while (true){
            final Socket socket = serverSocket.accept();
            executorService.execute(() -> {
                try {
                    service(socket);
                } catch (IOException e) {
                    e.printStackTrace();
                }
            });
        }
    }

    private static void service(Socket socket) throws IOException {
        PrintWriter printWriter = new PrintWriter(socket.getOutputStream(), true);
        printWriter.println("HTTP/1.1 200 OK");
        printWriter.println("Content-Type:text/html;charset=utf-8");
        String body = "hello, nio1";
        printWriter.println("Content-Length:" + body.getBytes().length);
        printWriter.println();
        printWriter.write(body);
        printWriter.close();
        socket.close();
    }
}
