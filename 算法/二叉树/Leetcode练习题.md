# 1302. 层数最深叶子节点的和

[1302. 层数最深叶子节点的和](https://leetcode.cn/problems/deepest-leaves-sum/)

给你一棵二叉树的根节点 `root` ，请你返回 **层数最深的叶子节点的和** 。

**示例 1：**

![img](.\image\leetcode_1302_01.png)

```shell
输入：root = [1,2,3,4,5,null,6,7,null,null,null,null,8]
输出：15
```

**示例 2：**

```shell
输入：root = [6,7,8,2,7,1,3,9,null,1,4,null,null,null,5]
输出：19
```

**提示：**

- 树中节点数目在范围 `[1, 104]` 之间。
- `1 <= Node.val <= 100`

## 方法一：深度优先搜索（递归）

```java
class Solution {
    int max = 0;
	int sum = 0;

    public int deepestLeavesSum(TreeNode root) {
    	help(root, 0);
    	return sum;
    }


    void help(TreeNode root, int level) {
    	if (root == null) {
    		return;
    	}
    	if (level > max) {
    		max = level;
    		sum = root.val;
    	} else if (level == max) {
    		sum += root.val;
    	}
    	help(root.left, level + 1);
    	help(root.right, level + 1);
    }
}
```



## 方法二：广度优先搜索

```java
/**
 * Definition for a binary tree node.
 * public class TreeNode {
 *     int val;
 *     TreeNode left;
 *     TreeNode right;
 *     TreeNode() {}
 *     TreeNode(int val) { this.val = val; }
 *     TreeNode(int val, TreeNode left, TreeNode right) {
 *         this.val = val;
 *         this.left = left;
 *         this.right = right;
 *     }
 * }
 */
class Solution {
    public int deepestLeavesSum(TreeNode root) {
        int ans = root.val;
        Queue<TreeNode> queue = new ArrayDeque<>();
        queue.offer(root);
        while (!queue.isEmpty()) {
            int size = queue.size();
            int sum = 0;
            for (int i = 0; i < size; i++) {
                TreeNode node = queue.poll();
                sum += node.val;
                if (node.left != null) {
                    queue.offer(node.left);
                }
                if (node.right != null) {
                    queue.offer(node.right);
                }
            }
            ans = sum;
        }
        return ans;
    }
}
```

