import android.content.Context;
import java.io.*;
import java.util.*;

public class FilterText {
    // private static final String RED = "\u001B[91m";
    // private static final String YELLOW = "\u001B[93m";
    // private static final String BLUE = "\u001B[94m";
    // private static final String RESET = "\u001B[0m";

    public static void filter(Context context, String sourceListPath, String exclusionListPath) {
        Set<String> exclusionList = new HashSet<>();
        if (!new File(exclusionListPath).exists() || new File(exclusionListPath).length() == 0) {
            // System.out.println(YELLOW + "警告：要过滤掉的字符串列表文件 '" + exclusionListPath + "' 不存在或为空" + RESET);
            System.exit(1);
        } else {
            try (BufferedReader blFile = new BufferedReader(new FileReader(exclusionListPath))) {
                String line;
                while ((line = blFile.readLine()) != null) {
                    if (line.trim().length() > 0 && !line.trim().startsWith("#")) {
                        exclusionList.add(line.trim());
                    }
                }
            } catch (IOException e) {
                // System.err.println(RED + "错误：读取排除列表文件 '" + exclusionListPath + "' 时发生错误：" + e + RESET);
                System.exit(1);
            }
        }

        List<String> apps = new ArrayList<>();
        try (BufferedReader appFile = new BufferedReader(new FileReader(sourceListPath))) {
            String line;
            while ((line = appFile.readLine()) != null) {
                if (line.trim().length() > 0 && !line.trim().startsWith("#")) {
                    apps.add(line.trim());
                }
            }
            if (apps.isEmpty()) {
                // System.out.println(YELLOW + "警告：'" + sourceListPath + "' 文件过滤后为空。" + RESET);
                System.exit(1);
            }
        } catch (FileNotFoundException e) {
            // System.err.println(RED + "错误：源列表文件 '" + sourceListPath + "' 不存在。" + RESET);
            System.exit(1);
        } catch (IOException e) {
            // System.err.println(RED + "错误：读取源列表文件 '" + sourceListPath + "' 时发生错误：" + e + RESET);
            System.exit(1);
        }

        List<String> filteredApps = new ArrayList<>();
        for (String app : apps) {
            if (!exclusionList.contains(app) && !app.trim().isEmpty()) {
                filteredApps.add(app);
            }
        }

        if (filteredApps.isEmpty()) {
            // System.out.println(YELLOW + "警告：没有字符串被过滤掉" + RESET);
            System.exit(1);
        } else {
            for (String app : filteredApps) {
                System.out.println(app);
            }
        }
    }

    public static void main(String[] args) {
        if (args.length != 3) {
            // System.out.println(BLUE + "用法: <文件名含后缀> <要执行过滤的文件> <过滤掉的字符串列表>" + RESET);
            System.exit(1);
        }

        String sourceListPath = args[1];
        String exclusionListPath = args[2];

        filter(null, sourceListPath, exclusionListPath);
    }
}