## Java浮点型数据等值比较

浮点型数据存在误差，等值比较会出现bug

    float f1 = 0.0f;
    for (int j = 0; j < 11; j++) {
        f1 += 0.1f;
    }
    float f2 = 0.1f * 11;
    System.out.println("f1 = " + f1);
    System.out.println("f2 = " + f2);
    if (f1 == f2) {
        System.out.println("f1 == f2 ");
    } else {
        System.out.println("f1 != f2");
    }
    
    ------------ 结果 ---------------
    f1 = 1.1000001
    f2 = 1.1
    f1 != f2
    
解决方法一：设置误差范围

    final float THRESHOLD = 0.000001f;
    float f1 = 0.0f;
    for (int j = 0; j < 11; j++) {
        f1 += 0.1f;
    }
    float f2 = 0.1f * 11;
    System.out.println("f1 = " + f1);
    System.out.println("f2 = " + f2);
    if (Math.abs(f1 - f2) < THRESHOLD) {
        System.out.println("f1 == f2 ");
    } else {
        System.out.println("f1 != f2");
    }

    ------------ 结果 ---------------
    f1 = 1.1000001
    f2 = 1.1
    f1 == f2 
    
解决方法二：使用 BigDecimal(注意构造必须使用String类型，否则仍然存在精度丢失问题)

    BigDecimal f1 = new BigDecimal("0.0");
    BigDecimal pointOne = new BigDecimal("0.1");
    for (int j = 0; j < 11; j++) {
        f1 = f1.add(pointOne);
    }
    BigDecimal f2 = new BigDecimal("0.1");
    BigDecimal eleven = new BigDecimal("11");
    f2 = f2.multiply(eleven);
    System.out.println("f1 = " + f1);
    System.out.println("f2 = " + f2);
    if (f1.compareTo(f2) == 0) {
        System.out.println("f1 == f2 ");
    } else {
        System.out.println("f1 != f2");
    }
    
    ------------ 结果 ---------------
    f1 = 1.1
    f2 = 1.1
    f1 == f2 