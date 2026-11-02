package com.epms;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
@MapperScan("com.epms.**.mapper")
public class EpmsApplication {
    public static void main(String[] args) {
        SpringApplication.run(EpmsApplication.class, args);
    }
}
