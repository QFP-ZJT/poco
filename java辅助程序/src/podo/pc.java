package podo;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.Scanner;

public class pc {

	static String input;
	static int base;
	static int basefordata;
	static int baseforstack = 255;
	static boolean error;
	private static Map<String, String> mapNameToPC; // PC 名字映射到 二进制
	private static Map<String, String> mapPara; // 参数映射关系 名称－－二进制
	private static Map<String, String> mapVar; // 变量映射关系 名称与指 有存在的必要吗？
	private static Map<String, String> mapVarLocation; // 变量名称 与 地址(二进制)
	private static FileWriter writer;
	static Scanner scan;

	public static void main(String[] args) throws IOException {
		mapNameToPC = new FileToMap1("＝", "助记符--PC").get();// 读取转换关系
		mapPara = new HashMap<String, String>();
		mapVar = new HashMap<String, String>();
		mapVarLocation = new HashMap<String, String>();
		writer = new FileWriter("PCFORRAM", false);
		Scanner scanner = new Scanner(System.in);
		System.out.print("欢迎使用简易编译器,请输入基地址与数据区开始位置\n");
		base = Integer.parseInt(scanner.next());
		basefordata = Integer.parseInt(scanner.next());
		String in_op = scanner.nextLine();
		while (true) {
			in_op = scanner.nextLine();
			scan = new Scanner(in_op);
			// PC指令生成
			String op = scan.next();
			switch (op) {
			case "LOAD":
				LOAD(); // LOAD MAR/PC/NUM Register
						// NUM 变量或者参数的值 自定义的值
				break;
			case "STORE":
				STORE(); // STORE MAR/PC Register
				break;
			case "PARA":
				PARA();
				break;
			case "VAR":
				VAR();// 方法内添加指令
				break;
			case "ALU":
				ALU();
				break;
			case "TR":
				TR();
				break;
			case "BP":// 设置断点
				BP();
				break;
			case "P":// 显示当前参数
				P();
				break;
			case "IO":
				IO();
				break;
			case "JUMP":
				JUMP();
				break;
			case "PROGRAMMER":// 记录程序起始的位置
				PROGRAMMER();
				break;
			case "PUSH":
				PUSH();
				break;
			case "PULL":
				PULL();
				break;
			case "STOP":
				w(mapNameToPC("停机"), "停机");
				w(mapNameToPC("停机"), "停机");
			case "END":
				writer.close();
				return;

			}

		}

	}

	private static void PULL() throws IOException {
		baseforstack++;
		w(mapNameToPC("LOAD_PC_" + scan.next()), "PULL");
		w(Integer.toBinaryString(baseforstack), "取数位置 =>" + baseforstack);
	}

	private static void PUSH() throws IOException {
		w(mapNameToPC("STORE_PC_" + scan.next()), "PUSH");
		w(Integer.toBinaryString(baseforstack), "压入位置 =>" + baseforstack);
		baseforstack--;
	}

	private static void BP() throws IOException {
		w(mapNameToPC("CH_INTERRUPT"), "断点");
	}

	private static void JUMP() throws IOException {
		String a0 = scan.next();// 跳转条件
		w(mapNameToPC("JUMP_" + a0), "JUMP" + a0);
	}

	private static void IO() throws IOException {
		String a0 = scan.next();
		String a1 = scan.next();
		if (a0.equals("IN"))
			w(mapNameToPC("CH_INTERRUPT"), "CH_INTERRUPT");
		w(mapNameToPC(a0 + "_" + a1), a0 + "_" + a1);
	}

	private static void PROGRAMMER() {
		String temp = scan.next();
		if (mapPara.get(temp) != null) {
			System.out.println("该参数名称在参数列表中出现过,请重新输入");
			return;
		}
		mapPara.put(temp, Integer.toBinaryString(base));
	}

	private static void P() {
		System.out.println("参数列表\n" + mapPara.toString());
		System.out.println("变量值列表\n" + mapVar.toString());
		System.out.println("变量地址列表\n" + mapVarLocation.toString());
		System.out.println("助记符--PC列表\n" + mapNameToPC.toString());
	}

	private static void TR() throws IOException {
		String a = scan.next() + "--" + scan.next();
		w(mapNameToPC(a), a);
	}

	/**
	 * 返回ALU指令
	 * 
	 * @return
	 * @throws IOException
	 */
	private static void ALU() throws IOException {
		String temp = "ALU_" + scan.next() + "_" + scan.next();
		w(mapNameToPC(temp), temp);
	}

	/**
	 * 存储指令
	 * 
	 * @return
	 * @throws IOException
	 */
	private static void STORE() throws IOException {
		String temp = null;
		String temp1 = null;
		String a = null;
		temp1 = scan.next();
		switch (temp1) {
		case "MAR": // M(MAR)寻址
			temp = scan.next();
			w(mapNameToPC("STORE_MAR_" + temp), "STORE_MAR" + temp);
			return;
		case "PC": // M(PC)寻址
			temp = scan.next();
			w(mapNameToPC("STORE_PC_" + temp), "STORE_PC" + temp);
			temp = scan.next();
			a = nameToValue(temp);
			if (a != null)
				w(a, "从nameToValue中获取的位置值");
			else
				try {
					w(Integer.toBinaryString(Integer.parseInt(temp)), "自定义位置");
				} catch (Exception e) {
					System.out.println("非法常数");
					return;
				}
			return;
		case "NUM":
			System.out.println("请使用VAR命令进行存储");
			break;
		default:
			System.out.println("无法将数据写到:" + temp1);
			return;
		}
	}

	// 变量存储指令
	private static void VAR() throws IOException {
		String temp = scan.next();// 获得变量名
		if (mapVar.get(temp) != null) {
			System.out.println("该名称在变量列表中出现过,请重新输入");
			return;
		}
		mapVar.put(temp, Integer.toBinaryString(Integer.parseInt(scan.next())));// 接收变量的值
		mapVarLocation.put(temp, Integer.toBinaryString(basefordata));// 记录变量的位置
		// 存储该变量
		w(mapNameToPC("STORE_NUM_PC"), "STORE_NUM_PC");
		w(Integer.toBinaryString(basefordata), "变量地址");// 位置
		w(mapVar.get(temp), "变量值");// 值
		basefordata++;
	}

	/**
	 * 接收10进制 存储二进制
	 */
	private static void PARA() {
		String temp = scan.next();
		if (mapPara.get(temp) != null) {
			System.out.println("该参数名称在参数列表中出现过,请重新输入");
			return;
		}
		mapPara.put(temp, Integer.toBinaryString(Integer.parseInt(scan.next())));
	}

	/**
	 * 装载指令
	 * 
	 * @return
	 * @throws IOException
	 */
	public static void LOAD() throws IOException {
		String temp = null;
		String temp1 = null;
		String a = null;
		temp1 = scan.next();
		switch (temp1) {
		case "PC": // M(PC)寻址
			temp = scan.next();
			w(mapNameToPC("LOAD_PC_" + temp), "LOAD_PC_" + temp);
			temp = scan.next();// 从变量列表中获取
			a = nameToLocation(temp);
			if (a == null) {
				a = nameToPara(temp);
				if (a != null)
					w(a, "从参数列表中定义的位置");
				else
					try {
						a = Integer.toBinaryString(Integer.parseInt(temp));
						w(a, "自己定义的位置");
					} catch (Exception e) {
						System.out.println("不是变量的地址，不是参数的值，也不是自定义的位置");
						return;
					}
			} else
				w(a, "从变量列表中获得变量的地址");
			break;
		case "NUM": // 立即数寻址
			temp = scan.next(); // R0 R1 LJ MAR
			w(mapNameToPC("LOAD_NUM_" + temp), "LOAD_NUM_" + temp);
			temp = scan.next();
			a = nameToValue(temp);
			if (a != null)
				w(a, "从nameToValue中获取的值");
			else
				try {
					w(Integer.toBinaryString(Integer.parseInt(temp)), "自定义值");
				} catch (Exception e) {
					System.out.println("非法常数");
					return;
				}
			break;
		case "MAR": // M(MAR)寻址
			temp = scan.next();// R0 R1 LJ MAR
			w(mapNameToPC("LOAD_MAR_" + temp), "LOAD_MAR_" + temp);
			break;
		default:
			System.out.println("无法从" + temp1 + "获取数据");
			return;
		}
	}

	/**
	 * 助记符转换到PC
	 * 
	 * @param input
	 * @return PC
	 */
	public static String mapNameToPC(String input) {
		String output = mapNameToPC.get(input);
		if (output == null) {
			System.out.println("无法转换成对应的NameToPC指令:" + input);
			return null;
		}
		System.out.println(input + "<==>" + output);
		return output;
	}

	/**
	 * 
	 * @param input
	 * @return
	 */
	public static String nameToPara(String input) {
		String output = mapPara.get(input);
		return output;
	}

	/**
	 * 从Para和Var列表中查找Value
	 * 
	 * @param input
	 * @return
	 */
	public static String nameToValue(String input) {
		String output = mapPara.get(input);
		if (output != null) {
			return output;
		} else {
			output = mapVar.get(input);
		}
		return output;
	}

	/**
	 * 获取变量到的位置
	 * 
	 * @param input
	 * @return
	 */
	public static String nameToLocation(String input) {
		String output = mapVarLocation.get(input);
		return output;
	}

	/**
	 * 记录
	 * 
	 * @param input
	 * @throws IOException
	 */
	public static void w(String input, String info) throws IOException {
		String temp;
		// System.out.println(input.length());
		if (input.length() > 8)
			input = input.substring(input.length() - 8);
		else {
			for (int i = input.length(); i < 8; i++)
				input = "0" + input;
		}
		System.out.println(info + ": " + input);
		try {
			input = Integer.toHexString(Integer.parseInt(Integer.valueOf(input, 2).toString()));// 二进制转十六进制
		} catch (Exception e) {
			System.out.println("W()出错:" + input);
		}
		// 记录备注
		// writer.write(info + "\n");
		// 补全
		for (int i = input.length(); i < 2; i++)
			input = "0" + input;
		if (base < 16) // 处理基地址
		{
			temp = "地址:\n0" + Integer.toHexString(base) + ";\n数据:\n" + input + ";\n";
			// System.out.println(temp);
			writer.write(temp);
		} else {
			temp = "地址:\n" + Integer.toHexString(base) + ";\n数据:\n" + input + ";\n";
			// System.out.println(temp);
			writer.write(temp);
		}
		base++;
	}

	/**
	 * MAP与文件之间的相互交换
	 * 
	 * @author zjtao
	 *
	 */
	public static class FileToMap1 {
		private static String line = System.getProperty("line.separator");
		private String separ = "=";
		static String basePath = System.getProperty("user.dir");
		static String filePath = "./upc助记符";// 文件相对路径

		public static Map<String, String> get() {
			FileToMap1 fileToMap1 = new FileToMap1();
			Map<String, String> oldMap = fileToMap1.fTM();
			return oldMap;
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
