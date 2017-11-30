package podo;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.Scanner;

public class upc {

	static String input;
	static String output;
	static int base;
	static boolean error;
	private static Map<String, String> map;
	private static Map<String, String> mapbase;// 微指令起始地址
	private static Map<String, String> mapNameToPC;// 微指令对应的PC值
	private static FileWriter writerupc;
	private static FileWriter writerdecode;

	public static void main(String[] args) throws IOException {
		try {
			writerupc = new FileWriter(new File("微指令ForMDR"), false);
			writerdecode = new FileWriter(new File("decodeForVerilog"), false);// 从头覆盖
		} catch (IOException e1) {
			// TODO Auto-generated catch block
			e1.printStackTrace();
		}
		map = FileToMap1.get();
		mapbase = new HashMap<String, String>();
		mapNameToPC = new HashMap<String, String>();
		String temp = null;
		// Scanner scan = new Scanner(System.in);
		Scanner scan = new Scanner(new File("excel"));
		error = false;
		System.out.print("欢迎使用微指令生成器,请输入基地址\n");
		base = 0;
		System.out.print("指令名(不输入指令名称，不记录该条地址) 名称  ALU  寄存器  写读  寄存器  写读 RAM地址输入  RAM写读  下地址声称方式\n");
		while (scan.hasNext()) {
			output = "";
			temp = "";
			temp = scan.next();// 检查是否是一条新的微指令起始位置

			if (temp.equals("op"))// 需要记录
			{
				temp = scan.next();
				mapbase.put(temp, "" + base);
				mapNameToPC.put(temp, scan.next());
				output += map_get(scan.next());// alu
			} else if (temp.equals("打印")) {
				System.out.println(mapbase.toString());
				continue;
			} else if (temp.equals("END")) {
				break;
			} else {// 若不需要纪录
				output += map_get(temp); // alu
			}

			output += map_get(scan.next());// register
			output += map_get(scan.next());// wr
			output += map_get(scan.next());// register
			output += map_get(scan.next());// wr
			output += map_get(scan.next());// 打印,中断,
			output += scan.next(); 		  // PC是否自动增一	
			output += map_get(scan.next());//RECORD USE RECORD&&USE
			output += map_get(scan.next());// ram addr
			output += map_get(scan.next());// ram wr
			temp = map_get(scan.next());// next
			output += temp;
			if (temp.equals("010"))// 实现跳转
			{
				temp = scan.next();
				// System.out.println(temp);
				temp = (mapbase_get(temp)); // 得到转移指令的地址 十进制 字符串
				temp = Integer.toBinaryString(Integer.parseInt(temp));// 转换成二进制
				for (int i = temp.length(); i < 8; i++) { // 补全0
					temp = "0" + temp;
				}
				// System.out.println(output);
				// System.out.println(temp);
				output = output.substring(0, 3) + temp + output.substring(11);
				// System.out.println(output);
			}

			// try {
			output = Integer.toHexString(Integer.parseInt(Integer.valueOf(output, 2).toString()));// 二进制转十六进制
			// } catch (Exception e) {
			// System.out.println(base);
			// }

			// 最终的输出打印
			if (base < 16) // 处理基地址
			{
				temp = "地址:\n0" + Integer.toHexString(base) + ";\n数据:\n" + output + ";\n";
				// System.out.println(temp);
				writerupc.write(temp);
			} else {
				temp = "地址:\n" + Integer.toHexString(base) + ";\n数据:\n" + output + ";\n";
				// System.out.println(temp);
				writerupc.write(temp);
			}
			base++;
		}
		writerupc.close();
		try {
			FileToMap1.mapToFileDefault(mapNameToPC, new File("助记符--PC"), "");
		} catch (IOException e) {
			// TODO Auto-generated catch block
			System.out.println("存储失败!");
		}
		/**
		 * 存储译码电路
		 */
		for (Map.Entry entry : mapNameToPC.entrySet()) {
			temp = "8'b";
			String ori = null;
			// ori = Integer.toBinaryString(j);//转换成二进制
			// for(int i = ori.length();i < 8;i++) {
			// ori = "0" + ori;
			// }
			temp += (String) entry.getValue();
			temp += ": out <= 8'b";
			ori = Integer.toBinaryString(Integer.parseInt(mapbase.get((String) entry.getKey())));
			for (int i = ori.length(); i < 8; i++) {
				ori = "0" + ori;
			}
			temp += ori;
			temp += (";\t// " + (String) entry.getValue() + " TO " + mapbase.get((String) entry.getKey()) + " \t"
					+ (String) entry.getKey() + "\n");
			writerdecode.write(temp);
		}
		writerdecode.close();
		System.out.println("Finished!");
	}

	public static String mapbase_get(String input) {
		String output = mapbase.get(input);
		if (output == null) {
			System.out.println("无法转换成对应的机器指令:" + input);
		}
		return output;
	}

	public static String map_get(String input) {
		String output = map.get(input);
		if (output == null) {
			System.out.println("无法转换成对应的机器指令:" + input);
		}
		return output;
	}

	public static class FileToMap1 {
		private static String line = System.getProperty("line.separator");
		private String separ = "=";
		static String basePath = System.getProperty("user.dir");
		static String filePath = "./upc助记符";// 文件相对路径

		public static Map<String, String> get() {
			FileToMap1 fileToMap1 = new FileToMap1();
			Map<String, String> oldMap = fileToMap1.fTM();
			return oldMap;
			// Map<String, String> newMap = new HashMap<String, String>();
			// newMap.put("A", "A''");
			// Map<String, String> map = fileToMap1.newMapToOldMap(newMap, oldMap, false);
			// try {
			// fileToMap1.mapToFileDefault(map, new File(filePath), fileToMap1.separ);
			// } catch (IOException e) {
			// e.printStackTrace();
			// }
		}

		/**
		 * 有参构造函数
		 * 
		 * @param separ
		 * @param filePath
		 */
		public FileToMap1(String separ, String filePath) {
			this.filePath = filePath;
			this.separ = separ;
			File file = new File(filePath);
			if (!file.exists()) {
				System.out.println("文件不存在");
				try {
					file.createNewFile();
				} catch (IOException e) {
					System.out.println("路径:" + filePath + "创建失败");
					e.printStackTrace();
				}
			}
		}

		/**
		 * 无参构造函数，用类默认的配置。
		 */
		public FileToMap1() {
			File file = new File(filePath);
			if (!file.exists()) {
				System.out.println("文件不存在");
				try {
					file.createNewFile();
				} catch (IOException e) {
					System.out.println("路径:" + filePath + "创建失败");
					e.printStackTrace();
				}
			}
		}

		/**
		 * 将map写入到file文件中。默认map（String A,String A')file中以A=A'来表示，map中每个键值对显示一行
		 * 
		 * @throws IOException
		 */
		public static File mapToFileDefault(Map<String, String> map, File file, String separ) throws IOException {
			StringBuffer buffer = new StringBuffer();
			FileWriter writer = new FileWriter(file, false);
			for (Map.Entry entry : map.entrySet()) {
				String key = (String) entry.getKey();
				String value = (String) entry.getValue();
				buffer.append(key + "=" + value).append(line);
			}
			writer.write(buffer.toString());
			writer.close();
			return file;
		}

		/**
		 * 在newMap替换oldMap时，是否覆盖（isOverwrite)如果是，就直接替换，如果否，则将oldMap中的key前加“#”，默认为否
		 * 
		 * @param newMap
		 * @param oldMap
		 * @return
		 */
		// private Map<String, String> newMapToOldMapDefault(Map<String, String> newMap,
		// Map<String, String> oldMap) {
		// return newMapToOldMap(newMap, oldMap, false);
		// }

		/**
		 * 在newMap替换oldMap时，是否覆盖（isOverwrite)如果是，就直接替换，如果否，则将oldMap中的key前加“#”，默认为否
		 */
		// private Map<String, String> newMapToOldMap(Map<String, String> newMap,
		// Map<String, String> oldMap,
		// boolean isOverwrite) {
		// // 由于oldMap中包含了file中更多内容，所以newMap中内容在oldMap中调整后，最后返回oldMap修改之后的map.
		// // 如果选择true覆盖相同的key
		// if (isOverwrite) {
		// // 循环遍历newMap
		// for (Map.Entry entry : newMap.entrySet()) {
		// String newKey = (String) entry.getKey();
		// String newValue = (String) entry.getValue();
		// oldMap.put(newKey, newValue);
		// }
		// } else {
		// // 不覆盖oldMap,需要在key相同的oldMap的key前加#；
		// // 循环遍历newMap
		// for (Map.Entry entry : newMap.entrySet()) {
		// String newKey = (String) entry.getKey();
		// String newValue = (String) entry.getValue();
		// String oldValue = oldMap.get(newKey);
		// oldMap.put("#" + newKey, oldValue);
		// oldMap.put(newKey, newValue);
		// }
		// }
		// return oldMap;
		// }

		/**
		 * 将文件转换成map存储
		 * 
		 * @return
		 */
		private Map<String, String> fTM() {
			Map<String, String> map = new HashMap<String, String>();
			File file = new File(filePath);
			BufferedReader reader = null;
			try {
				// System.out.println("以行为单位读取文件内容，一次读一整行：");
				reader = new BufferedReader(new FileReader(file));
				String tempString = null;
				int line = 1;
				// 一次读入一行，直到读入null为文件结束
				while ((tempString = reader.readLine()) != null) {
					// 显示行号
					// System.out.println("line " + line + ": " + tempString);
					if (!tempString.startsWith("#")) {
						String[] strArray = tempString.split("=");
						map.put(strArray[0], strArray[1]);
					}
					line++;
				}
				reader.close();
			} catch (IOException e) {
				e.printStackTrace();
			} finally {
				if (reader != null) {
					try {
						reader.close();
					} catch (IOException e1) {
					}
				}
			}
			return map;
		}

	}

}
