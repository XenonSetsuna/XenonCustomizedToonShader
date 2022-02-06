using UnityEngine;
using System.Collections;


public class getVertex : MonoBehaviour
{
	//Æ«ÒÆÁ¿
	public Vector3 offset;

	public bool showGiz = true;

	public MeshFilter mesh;
	public GameObject model;
	public Material met;

	public float r=0.1f;

	public int left = 406;
	public int right = 1083;
	public int faceDir = 887;

	private Vector3[] vertices;
	private Vector3 pos;
	private Vector3 nor;
	
	void Start()
	{
		
	}
    private void Update()
    {

		//pos = mesh.sharedMesh.vertices[114];
		pos = mesh.sharedMesh.vertices[left] + mesh.sharedMesh.vertices[right];
		pos /= 2;
		nor = mesh.sharedMesh.normals[faceDir];
		nor.Normalize();

		pos =model.transform.TransformPoint(pos+nor*offset.x);
		met.SetVector("_HeadCenter", new Vector4(pos.x,pos.y,pos.z,1.0f) );
	}
    void OnDrawGizmos()
    {
        //mesh.sharedMesh.normals[694];
        if (showGiz)
        {
			pos = mesh.sharedMesh.vertices[left] + mesh.sharedMesh.vertices[right];
			pos /= 2;
			nor = mesh.sharedMesh.normals[faceDir];
			Vector3 targetPosition = model.transform.TransformPoint(pos + nor * offset.x);
			Gizmos.color = Color.red;
			Gizmos.DrawSphere(targetPosition, r);
		}
		
		
    }

}