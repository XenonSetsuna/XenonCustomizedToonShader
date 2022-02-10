using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;
using UnityEditor;
using System.Text;
using System.Text.RegularExpressions;

public class NormalEditor : MonoBehaviour
{

    public GameObject Face;
    public Vector3 HeadCenter;
    public float FixStrength = 1.0f;
    public bool Activate = false;
    public bool ReturnToOrigin = false;
    public bool Backup = false;

    public string FileName = "法线备份.txt";
    // Start is called before the first frame update
    private void Start()
    {
        
    }
    // Update is called once per frame
    void Update()
    {
        if (Activate)
        {
            Vector3[] LoadedNormals;
            SkinnedMeshRenderer SMR = Face.GetComponent<SkinnedMeshRenderer>();
            try
            {
                LoadedNormals = Load(FileName, SMR.sharedMesh.normals.Length);
            }
            catch
            {
                Debug.Log("未检测到原法线备份信息，正在执行自动备份");
                doBackup();
            }
            LoadedNormals = Load(FileName, SMR.sharedMesh.normals.Length);
            doNormalFix(LoadedNormals, FixStrength);
            Activate = false;
        }
        if (ReturnToOrigin)
        {
            doReturn();
            ReturnToOrigin = false;
        }
        if (Backup)
        {
            doBackup();
            Backup = false;
        }
    }

    void doNormalFix(Vector3[] OriginalNormals, float Percentage)
    {
        SkinnedMeshRenderer SMR = Face.GetComponent<SkinnedMeshRenderer>();
        Vector3[] Normals = new Vector3[SMR.sharedMesh.vertices.Length];

        for (int i = 0; i < SMR.sharedMesh.vertices.Length; i++)
        {
            Normals[i] = SMR.sharedMesh.vertices[i] - Face.transform.InverseTransformPoint(HeadCenter);
            Normals[i].Normalize();
            OriginalNormals[i].Normalize();
            Normals[i] = Normals[i] * Percentage + OriginalNormals[i] * (1 - Percentage);
        }
        SMR.sharedMesh.SetNormals(Normals);
        Debug.Log("法线修改成功");
    }
    void doReturn()
    {
        SkinnedMeshRenderer SMR = Face.GetComponent<SkinnedMeshRenderer>();
        try
        {
            Vector3[] Normals = Load(FileName, SMR.sharedMesh.normals.Length);
            SMR.sharedMesh.SetNormals(Normals);
            Debug.Log("已还原法线");
        }
        catch
        {
            Debug.Log("未检测到法线备份信息");
        }
    }
    void doBackup()
    {
        SkinnedMeshRenderer SMR = Face.GetComponent<SkinnedMeshRenderer>();
        Save(FileName, SMR.sharedMesh.normals.Length, SMR.sharedMesh.normals);
        Debug.Log("法线信息备份成功");
    }

    //感谢hxd帮忙写的IO操作
    public void Save(string fileName, int size, Vector3[] v)
    {
        TextAsset txt = Resources.Load(fileName) as TextAsset;
        string createName = Application.dataPath + "/" + fileName;
        if (!File.Exists(createName))
        {
            File.Create(createName).Close();
        }
        string temp = "";
        for (int i = 0; i < size; ++i)
        {
            temp = temp + v[i].ToString() + '/';
        }

        StreamWriter fileWriter = new StreamWriter(createName);
        fileWriter.WriteLine(temp);
        fileWriter.Close();

    }
    public Vector3[] Load(string fileName, int size)
    {
        string createName = Application.dataPath + "/" + fileName;
        StreamReader sr = new StreamReader(createName);
        string txt = sr.ReadToEnd();
        Regex reg = new Regex(@"[()]");  //去掉()
        string a1 = reg.Replace(txt, "");
        string[] str = a1.Split('/');


        Vector3[] v = new Vector3[size];

        for (int i = 0; i < size; i++)
        {
            string[] s = str[i].Split(',');
            v[i] = new Vector3(float.Parse(s[0]), float.Parse(s[1]), float.Parse(s[2]));
        }
        foreach (var item in v)
        {
            
        }
        sr.Close();
        return v;

    }
}
