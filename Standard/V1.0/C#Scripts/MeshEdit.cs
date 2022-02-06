using UnityEngine;
using System.Collections.Generic;
using System.Text;
using TMPro;

public class MeshEdit : MonoBehaviour
{
    public GameObject text;
    public float size = 10f;
    private void Start()
    {
       
        MeshFilter targetFilter = GetComponentInChildren<MeshFilter>();
        Mesh mh = targetFilter.sharedMesh;
        Material material = new Material(Shader.Find("Unlit/Color"));
        material.color = Color.green;
        for (int i = 0; i < mh.vertices.Length; i++)
        {
            GameObject point = GameObject.CreatePrimitive(PrimitiveType.Sphere);
            point.name="v"+i.ToString();
            point.transform.parent = text.transform;
            point.transform.position = transform.TransformPoint(mh.vertices[i]);
            point.transform.localScale = Vector3.one*size;
            point.GetComponent<Renderer>().material = material;
            Destroy(point.GetComponent<Collider>());

        }

    }
   

}