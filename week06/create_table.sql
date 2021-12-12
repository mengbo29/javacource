CREATE TABLE `goods`  (
  `goods_id` int(11) NOT NULL AUTO_INCREMENT COMMENT '商品id，自增主键',
  `goods_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '商品名',
  `price` decimal(10, 2) NOT NULL COMMENT '单价',
  `description` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '商品描述信息',
  `create_time` datetime(0) NOT NULL COMMENT '本记录创建时间',
  `update_time` datetime(0) NULL DEFAULT NULL COMMENT '本记录修改时间',
  PRIMARY KEY (`goods_id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '商品信息表' ROW_FORMAT = Dynamic;

CREATE TABLE `order`  (
  `order_id` int(11) NOT NULL AUTO_INCREMENT COMMENT '订单号，自增主键',
  `user_id` int(11) NOT NULL COMMENT '下单用户id',
  `state` int(1) NOT NULL COMMENT '订单状态，0-已提交未付款，1-已付款，2-已收货，3-售后处理中，4-已退款',
  `order_create_time` datetime(0) NOT NULL COMMENT '订单提交时间',
  `pay_time` datetime(0) NULL DEFAULT NULL COMMENT '付款时间',
  `receive_info_id` int(11) NOT NULL COMMENT '收货信息id',
  `create_time` datetime(0) NOT NULL COMMENT '本记录创建时间',
  `update_time` datetime(0) NULL DEFAULT NULL COMMENT '本记录修改时间',
  PRIMARY KEY (`order_id`) USING BTREE,
  INDEX `index_user_id`(`user_id`) USING BTREE COMMENT '索引-用户id'
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '订单信息表' ROW_FORMAT = Dynamic;

CREATE TABLE `order_goods_relation`  (
  `order_goods_relation_id` int(11) NOT NULL AUTO_INCREMENT COMMENT '自增id',
  `order_id` int(11) NOT NULL COMMENT '订单id',
  `goods_id` int(11) NOT NULL COMMENT '商品id',
  `quantity` int(11) NOT NULL COMMENT '购买数量',
  `create_time` datetime(0) NOT NULL COMMENT '本记录创建时间',
  `update_time` datetime(0) NULL DEFAULT NULL COMMENT '本记录修改时间',
  PRIMARY KEY (`order_goods_relation_id`) USING BTREE,
  INDEX `index_order_id`(`order_id`) USING BTREE COMMENT '索引-订单id',
  INDEX `index_goods_id`(`goods_id`) USING BTREE COMMENT '索引-商品id'
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '订单和商品信息关系表' ROW_FORMAT = Dynamic;

CREATE TABLE `receive_info`  (
  `receive_info_id` int(11) NOT NULL AUTO_INCREMENT COMMENT '收货信息id，自增主键',
  `belonged_user_id` int(11) NOT NULL COMMENT '归属用户id',
  `receiver_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '收货人姓名',
  `receiver_phone` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '收货人手机号',
  `recerver_address` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '收货人地址',
  `create_time` datetime(0) NOT NULL COMMENT '本记录创建时间',
  `update_time` datetime(0) NULL DEFAULT NULL COMMENT '本记录修改时间',
  PRIMARY KEY (`receive_info_id`) USING BTREE,
  INDEX `index_belonged_user_id`(`belonged_user_id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '收货信息表' ROW_FORMAT = Dynamic;

CREATE TABLE `stock`  (
  `stock_id` int(11) NOT NULL AUTO_INCREMENT COMMENT '库存信息id，自增主键',
  `warehouse_id` int(11) NOT NULL COMMENT '仓库id',
  `goods_id` int(11) NOT NULL COMMENT '商品id',
  `max_quantity` int(11) NOT NULL COMMENT '最大可存储数量',
  `current_quantity` int(11) NOT NULL COMMENT '当前库存数量',
  `create_time` datetime(0) NOT NULL COMMENT '本记录创建时间',
  `update_time` datetime(0) NULL DEFAULT NULL COMMENT '本记录修改时间',
  PRIMARY KEY (`stock_id`) USING BTREE,
  INDEX `index_warehouse_id`(`warehouse_id`) USING BTREE COMMENT '索引-仓库id',
  INDEX `index_goods_id`(`goods_id`) USING BTREE COMMENT '索引-商品id'
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '库存信息表' ROW_FORMAT = Dynamic;

CREATE TABLE `user`  (
  `user_id` int(11) NOT NULL AUTO_INCREMENT COMMENT '用户id，自增主键',
  `user_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '姓名',
  `phone` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '手机号',
  `create_time` datetime(0) NOT NULL COMMENT '本记录创建时间',
  `update_time` datetime(0) NULL DEFAULT NULL COMMENT '本记录修改时间',
  PRIMARY KEY (`user_id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '用户信息表' ROW_FORMAT = Dynamic;

CREATE TABLE `warehouse`  (
  `warehouse_id` int(11) NOT NULL AUTO_INCREMENT COMMENT '仓库id，自增主键',
  `warehouse_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '仓库名称',
  `address` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '仓库地址',
  `create_time` datetime(0) NOT NULL COMMENT '本记录创建时间',
  `update_time` datetime(0) NULL DEFAULT NULL COMMENT '本记录修改时间',
  PRIMARY KEY (`warehouse_id`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '仓库信息表' ROW_FORMAT = Dynamic;

